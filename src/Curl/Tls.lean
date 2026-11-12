module

@[expose] public section

/-! A TLS server over OpenSSL — the other side of libcurl: a listening socket, a server context from a
certificate and its key, connections accepted, read and written, and a self-signed certificate made on
the spot. For tests and mocks served over https on the loopback; errors are messages. -/

namespace Curl.Tls

/-- A server context: the certificate presented and its key. -/
opaque Context : Type := Unit

/-- An accepted connection, its handshake done. -/
opaque Connection : Type := Unit

/-- The actions that can fail, with a message. -/
abbrev TlsIO : Type → Type := EIO String

scoped instance : MonadLift TlsIO IO := ⟨EIO.toIO IO.userError⟩

namespace Extern

@[extern "lean_tls_self_signed"]
opaque selfSigned (cn san : @& String) (days : UInt32) (certPath keyPath : @& String) : TlsIO Unit

@[extern "lean_tls_listen"]
opaque listen (host : @& String) (port : UInt32) : TlsIO UInt64

@[extern "lean_tls_server_context"]
opaque serverContext (certPath keyPath : @& String) : TlsIO Context

@[extern "lean_tls_accept"]
opaque accept (ctx : @& Context) (fd : UInt32) : TlsIO Connection

@[extern "lean_tls_read"]
opaque read (c : @& Connection) (max : UInt32) : TlsIO ByteArray

@[extern "lean_tls_write"]
opaque write (c : @& Connection) (bytes : @& ByteArray) : TlsIO Unit

@[extern "lean_tls_close"]
opaque close (c : @& Connection) : TlsIO Unit

end Extern

/-- An RSA-2048 key and a self-signed X.509 v3 certificate for `cn` with the subjectAltName `san`
(e.g. `IP:127.0.0.1,DNS:localhost`), valid `days` days from now, written as PEM to the two paths. -/
def selfSigned (cn san : String) (days : UInt32) (certPath keyPath : String) : TlsIO Unit :=
  Extern.selfSigned cn san days certPath keyPath

/-- A listening socket and the port it listens on. -/
structure Listener where
  fd : UInt32
  port : UInt16

/-- A TCP socket bound to `host:port` (an IPv4 address; port 0 for any free one), listening. -/
def listen (host : String) (port : UInt16) : TlsIO Listener := do
  let packed ← Extern.listen host port.toUInt32
  pure { fd := (packed >>> 32).toUInt32, port := (packed &&& 0xFFFF).toUInt16 }

/-- A server context presenting the certificate at `certPath`, signed with the key at `keyPath`. -/
def serverContext (certPath keyPath : String) : TlsIO Context :=
  Extern.serverContext certPath keyPath

/-- The next connection on the listener, its TLS handshake done (an error when the handshake fails:
the server goes on with the next connection). -/
def accept (ctx : Context) (l : Listener) : TlsIO Connection :=
  Extern.accept ctx l.fd

/-- Up to `max` bytes from the connection; empty once the peer has closed. -/
def read (c : Connection) (max : UInt32 := 65536) : TlsIO ByteArray :=
  Extern.read c max

/-- All of `bytes` to the connection. -/
def write (c : Connection) (bytes : ByteArray) : TlsIO Unit :=
  Extern.write c bytes

/-- The session shut down and the socket closed. -/
def close (c : Connection) : TlsIO Unit :=
  Extern.close c

end Curl.Tls
