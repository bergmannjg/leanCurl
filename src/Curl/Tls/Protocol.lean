module

public import Curl.Tls

@[expose] public section

/-! The protocol a program follows on `Curl.Tls`, twice over.

As a *model*: `Cmd` is one call on a listener or on one of its connections, `step` says which calls the
shim answers and which it refuses with a message ("connection closed", "listener closed"); `run` plays
a trace. The theorems say what the shim's contract means: a read or write after `close` is stuck,
`close` and `closeListener` are idempotent, and every trace of a program written with `withConnection`
runs without a stuck step.

As an *API*: `withConnection ctx l body` accepts one connection, hands `body` an `Open` handle whose only
operations are `Open.read` and `Open.write`, and closes the connection when `body` ends, however it ends.
Within the bracket nothing can close the connection (`Open` has no `close`, its connection is private), so
every `read`/`write` there is on an open connection — the model's `withConnection_runs`. Lean has no
linear types: a body that returns or stores its handle keeps a name for a closed connection, and a later
`Open.read`/`Open.write` on it fails with "connection closed" (an error, never a crash); keep handles
inside their bracket.

Nothing here proves OpenSSL or the C shim right: the model's `step` *is* the shim's documented contract,
checked by `lake exe test`; the theorems are about programs written against that contract.

**References.** `Cmd`, `St`, `step`, `run`, `Body` and the theorems are this library's contract — which
calls it answers, which it refuses; each theorem's docstring says whether an RFC requires the behaviour
(only `write_after_close_stuck` does: RFC 8446 §6.1 / RFC 5246 §7.2.1, no messages after `close_notify`),
whether the library is stricter than the RFC (`read_after_close_stuck`), or whether no RFC applies (the
listener, a second close). What the RFCs require of `close` itself — "Each party MUST send a
close_notify alert before closing its write side of the connection" (RFC 8446 §6.1) — is met by the shim
(`SSL_shutdown` before `close(2)`), trusted, not proved here. The only RFC-defined event in the model is
`close`: it stands for `Curl.Tls.close`, the `close_notify` alert of RFC 8446 §6.1 / RFC 5246 §7.2.1
followed by the socket's close; `read` and `write` stand for application data of RFC 8446 §5.1 /
RFC 5246 §6.2, and `accept` for a completed handshake, RFC 8446 §4 / RFC 5246 §7.4. -/

namespace Curl.Tls

/-- One call on a listener or on a connection numbered by its order of acceptance (this library's
operations, see the module's references; no RFC defines them). -/
inductive Cmd
  | accept (c : Nat)
  | read (c : Nat)
  | write (c : Nat)
  | close (c : Nat)
  | closeListener
  deriving DecidableEq, Repr

/-- The model's state: whether the listener is open, the connections accepted, those closed. -/
structure St where
  listening : Bool := true
  accepted : List Nat := []
  closed : List Nat := []
  deriving Repr

/-- `c` is accepted and not closed. -/
def St.isOpen (s : St) (c : Nat) : Prop := c ∈ s.accepted ∧ c ∉ s.closed

instance (s : St) (c : Nat) : Decidable (s.isOpen c) := by unfold St.isOpen; infer_instance

/-- One call: the state after it, or `none` where the shim answers an error. -/
def step (s : St) : Cmd → Option St
  | .accept c => if s.listening then some { s with accepted := c :: s.accepted } else none
  | .read c => if s.isOpen c then some s else none
  | .write c => if s.isOpen c then some s else none
  | .close c => if c ∈ s.accepted then some { s with closed := c :: s.closed } else none
  | .closeListener => some { s with listening := false }

/-- A trace played from `s`; `none` as soon as a call is stuck. -/
def run (s : St) : List Cmd → Option St
  | [] => some s
  | k :: ks => (step s k).bind fun s' => run s' ks

/-- A read on a closed connection is stuck ("connection closed"). This library's contract, stricter than
the RFCs: sending `close_notify` "does not have any effect on its read side of the connection"
(RFC 8446 §6.1, fourth paragraph), but `Curl.Tls.close` also closes the socket, so no read side remains. -/
theorem read_after_close_stuck (s : St) (c : Nat) :
    step { s with closed := c :: s.closed } (.read c) = none := by
  simp [step, St.isOpen]

/-- So is a write — here the RFCs do speak: `close` sent `close_notify`, which "notifies the recipient that
the sender will not send any more messages on this connection" (RFC 8446 §6.1, definition of
`close_notify`; RFC 5246 §7.2.1, same words), so a later write would break that promise and is refused. -/
theorem write_after_close_stuck (s : St) (c : Nat) :
    step { s with closed := c :: s.closed } (.write c) = none := by
  simp [step, St.isOpen]

/-- An accept on a closed listener is stuck ("listener closed"). POSIX sockets, no RFC. -/
theorem accept_after_closeListener_stuck (s : St) (c : Nat) :
    step { s with listening := false } (.accept c) = none := by
  simp [step]

/-- Closing a closed connection is not an error: it stays closed. The RFCs say nothing of a second close
(a `close_notify` is sent once, by the first `close`); this is the library's choice. -/
theorem close_idem (s : St) (c : Nat) (h : c ∈ s.accepted) :
    step { s with closed := c :: s.closed } (.close c) = some { s with closed := c :: c :: s.closed } := by
  simp [step, h]

/-- Closing the listener twice is not an error either. POSIX sockets, no RFC. -/
theorem closeListener_idem (s : St) :
    step { s with listening := false } .closeListener = some { s with listening := false } := by
  simp [step]

/-! ## Programs on one connection -/

/-- What a body may do with its `Open` handle: read, write, or nothing, in sequence. -/
inductive Body
  | done
  | read (k : Body)
  | write (k : Body)

/-- The body's calls on connection `c`. -/
def Body.trace (c : Nat) : Body → List Cmd
  | .done => []
  | .read k => .read c :: k.trace c
  | .write k => .write c :: k.trace c

/-- `withConnection`'s trace: accept, the body, close. -/
def withConnectionTrace (c : Nat) (b : Body) : List Cmd :=
  .accept c :: b.trace c ++ [.close c]

/-- A body's calls never get stuck while its connection is open, and leave the state as it was.

The RFC behind it: once the handshake is complete (RFC 8446 §4 / RFC 5246 §7.4) and until a
`close_notify` (RFC 8446 §6.1 / RFC 5246 §7.2.1), either party may send application data at any time,
in any amount — "Application Data messages contain data that is opaque to TLS" (RFC 8446 §5.1);
"treated as transparent data to the record layer" (RFC 5246 §6.2) — so TLS puts no order or limit on a
body's reads and writes, and none appears in the model: every `Body` runs. What the model adds, the
RFC does not: that `read`/`write` are the body's *only* operations. -/
theorem Body.run_open (b : Body) (s : St) (c : Nat) (h : s.isOpen c) :
    run s (b.trace c) = some s := by
  induction b with
  | done => rfl
  | read k ih => simp [Body.trace, run, step, h, ih]
  | write k ih => simp [Body.trace, run, step, h, ih]

/-- A trace that runs to `s'` continues from there. -/
theorem run_append_of_some {s s' : St} {xs ys : List Cmd} (h : run s xs = some s') :
    run s (xs ++ ys) = run s' ys := by
  induction xs generalizing s with
  | nil => simp [run] at h; subst h; rfl
  | cons k ks ih =>
    simp only [List.cons_append, run] at h ⊢
    cases hk : step s k with
    | none => simp [hk] at h
    | some t => simp only [hk, Option.bind_some] at h ⊢; exact ih h

/-- The protocol theorem: on a listening state, `withConnection` with any body runs to completion — no
call stuck — and ends with the connection closed. -/
theorem withConnection_runs (s : St) (c : Nat) (b : Body) (hl : s.listening = true)
    (hc : c ∉ s.closed) :
    run s (withConnectionTrace c b) = some { s with accepted := c :: s.accepted, closed := c :: s.closed } := by
  have hopen : ({ s with accepted := c :: s.accepted } : St).isOpen c := by
    simp [St.isOpen, hc]
  have h1 : run s [.accept c] = some { s with accepted := c :: s.accepted } := by simp [run, step, hl]
  have h12 : run s ([.accept c] ++ b.trace c) = some { s with accepted := c :: s.accepted } := by
    rw [run_append_of_some h1]; exact Body.run_open b _ c hopen
  have hsplit : (Cmd.accept c :: b.trace c ++ [.close c]) = ([.accept c] ++ b.trace c) ++ [.close c] := by simp
  simp only [withConnectionTrace]
  rw [hsplit, run_append_of_some h12]
  simp [run, step]

/-- After the bracket, the connection is closed. -/
theorem withConnection_closed (s : St) (c : Nat) :
    ¬ ({ s with accepted := c :: s.accepted, closed := c :: s.closed } : St).isOpen c := by
  simp [St.isOpen]

end Curl.Tls

end

/-! ## The API -/

namespace Curl.Tls

/-- A connection within its `withConnection` bracket: it can be read and written, and nothing else; it is
closed when the bracket ends. Only `withConnection` makes one (constructor and connection are private), so
within the bracket no one can close it. A handle kept past its bracket names a closed connection: its
reads and writes then fail with "connection closed". -/
public structure Open where
  private mk ::
  private conn : Connection

/-- Up to `max` bytes from the connection; empty once the peer has closed. -/
public def Open.read (o : Open) (max : UInt32 := 65536) : TlsIO ByteArray := Tls.read o.conn max

/-- All of `bytes` to the connection. -/
public def Open.write (o : Open) (bytes : ByteArray) : TlsIO Unit := Tls.write o.conn bytes

/-- One connection accepted on the listener, `body` run on it, the connection closed when `body` ends —
by return or by error (`close`: the `close_notify` alert of RFC 8446 §6.1 / RFC 5246 §7.2.1, then the
socket). The trace is `withConnectionTrace`, so `withConnection_runs` applies. -/
public def withConnection (ctx : Context) (l : Listener) (body : Open → TlsIO α) : TlsIO α := do
  let c ← accept ctx l
  try body { conn := c } finally close c

end Curl.Tls
