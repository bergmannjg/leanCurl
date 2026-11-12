module

@[expose] public section

/-! A TLS server over OpenSSL — the other side of libcurl: a listening socket, a server context from a
certificate and its key, connections accepted, read and written, and a self-signed certificate made on
the spot. For tests and mocks served over https on the loopback; errors are messages.

**References.** Each definition's docstring names the specification it follows, by RFC number and
section (RFCs do not change once published, so the number is the version):
* TLS 1.3 — RFC 8446 (August 2018); TLS 1.2 — RFC 5246 (August 2008). The handshake, record and alert
  protocols are OpenSSL's; this module only decides which version floor, what the server presents, and
  what it asks for.
* X.509 certificates — RFC 5280 (May 2008): the fields and extensions `selfSigned` writes, and the path
  validation (§6.1) the *client* (libcurl) runs against them.
* Server identity for https — RFC 2818 §3.1 (May 2000) for an IP address in the URL, RFC 6125 §6.4
  (March 2011) for a DNS name: how the client matches the URL's host against `subjectAltName`.
Where a definition follows no RFC (sockets, the library's own contract), its docstring says so. -/

namespace Curl.Tls

/-- A server context: the certificate presented (RFC 8446 §4.4.2 / RFC 5246 §7.4.2, the server's
Certificate message) and the key it signs with. -/
opaque Context : Type := Unit

/-- An accepted connection, its handshake (RFC 8446 §4 / RFC 5246 §7.4) done: application data flows
over the record protocol (RFC 8446 §5.1 / RFC 5246 §6.2). -/
opaque Connection : Type := Unit

/-- A listening socket (POSIX `socket`/`bind`/`listen`, no RFC); closed when it is dropped or by
`closeListener`. -/
opaque Listener : Type := Unit

/-- The actions that can fail, with a message. -/
abbrev TlsIO : Type → Type := EIO String

scoped instance : MonadLift TlsIO IO := ⟨EIO.toIO IO.userError⟩

namespace Extern

@[extern "lean_tls_self_signed"]
opaque selfSigned (cn san : @& String) (days : UInt32) (certPath keyPath : @& String) : TlsIO Unit

@[extern "lean_tls_listen"]
opaque listen (host : @& String) (port : UInt32) : TlsIO Listener

@[extern "lean_tls_listener_port"]
opaque listenerPort (l : @& Listener) : UInt32

@[extern "lean_tls_listener_close"]
opaque listenerClose (l : @& Listener) : TlsIO Unit

@[extern "lean_tls_server_context"]
opaque serverContext (certPath keyPath : @& String) : TlsIO Context

@[extern "lean_tls_accept"]
opaque accept (ctx : @& Context) (l : @& Listener) : TlsIO Connection

@[extern "lean_tls_read"]
opaque read (c : @& Connection) (max : UInt32) : TlsIO ByteArray

@[extern "lean_tls_write"]
opaque write (c : @& Connection) (bytes : @& ByteArray) : TlsIO Unit

@[extern "lean_tls_close"]
opaque close (c : @& Connection) : TlsIO Unit

end Extern

/-- An RSA-2048 key and a self-signed X.509 v3 certificate for `cn` with the subjectAltName `san`
(e.g. `IP:127.0.0.1,DNS:localhost`), valid `days` days from now, written as PEM to the two paths.

RFC 5280 correspondence, field by field: version 3 (§4.1.2.1); a positive serial number, the creation
time (§4.1.2.2); issuer = subject = `CN=cn` (§4.1.2.4, §4.1.2.6 — "self-signed": the issuer is the
subject and the signature verifies with the certificate's own key, §6.1 trust anchor); validity
`[now, now + days]` (§4.1.2.5); the extensions `subjectAltName` from `san` (§4.2.1.6: `IP:` an
iPAddress, `DNS:` a dNSName — what the client matches the URL against, RFC 2818 §3.1 / RFC 6125 §6.4),
`basicConstraints critical, CA:TRUE` (§4.2.1.9, so the certificate may be its own trust anchor), and
`subjectKeyIdentifier` (§4.2.1.2); signed sha256WithRSAEncryption. The files are PEM (RFC 7468 §5 and
§10); the key file is mode 0600 — no RFC, a precaution. -/
def selfSigned (cn san : String) (days : UInt32) (certPath keyPath : String) : TlsIO Unit :=
  Extern.selfSigned cn san days certPath keyPath

/-- A TCP socket bound to `host:port` (an IPv4 address; port 0 for any free one), listening; the
socket is closed when the listener is dropped, or by `closeListener`. POSIX sockets, no RFC. -/
def listen (host : String) (port : UInt16) : TlsIO Listener :=
  Extern.listen host port.toUInt32

/-- The port the listener is bound to. -/
def port (l : Listener) : UInt16 := (Extern.listenerPort l).toUInt16

/-- The listening socket closed; a later `accept` fails. -/
def closeListener (l : Listener) : TlsIO Unit := Extern.listenerClose l

/-- A server context presenting the certificate chain at `certPath` (RFC 8446 §4.4.2 / RFC 5246 §7.4.2:
the leaf first, then its intermediates), signing with the key at `keyPath`. It negotiates TLS 1.3
(RFC 8446) or TLS 1.2 (RFC 5246) and refuses anything below (RFC 8446 §4.2.1 `supported_versions` /
RFC 5246 Appendix E); it sends no CertificateRequest (RFC 8446 §4.3.2 / RFC 5246 §7.4.4), so clients are
not authenticated. -/
def serverContext (certPath keyPath : String) : TlsIO Context :=
  Extern.serverContext certPath keyPath

/-- The next connection on the listener, its TLS handshake done — RFC 8446 §4 (ClientHello … Finished)
or RFC 5246 §7.4, run by OpenSSL. A handshake that fails (the peer speaks plain HTTP, rejects the
certificate, offers no common version or cipher suite — RFC 8446 §4.1.1 / RFC 5246 §7.4.1) is an error
here, and the listener goes on with the next connection. -/
def accept (ctx : Context) (l : Listener) : TlsIO Connection :=
  Extern.accept ctx l

/-- Up to `max` bytes of application data from the connection (RFC 8446 §5.1 / RFC 5246 §6.2, one or
more records' worth); empty once the peer has closed — its `close_notify` alert received (RFC 8446 §6.1 /
RFC 5246 §7.2.1), or its TCP connection gone. -/
def read (c : Connection) (max : UInt32 := 65536) : TlsIO ByteArray :=
  Extern.read c max

/-- All of `bytes` to the connection as application data (RFC 8446 §5.1 / RFC 5246 §6.2; OpenSSL splits
them into records of at most 2^14 bytes, RFC 8446 §5.1 / RFC 5246 §6.2.1). -/
def write (c : Connection) (bytes : ByteArray) : TlsIO Unit :=
  Extern.write c bytes

/-- The session shut down — a `close_notify` alert sent (RFC 8446 §6.1 / RFC 5246 §7.2.1), the peer's
not awaited — and the socket closed; a later `read` or `write` fails with "connection closed". -/
def close (c : Connection) : TlsIO Unit :=
  Extern.close c

end Curl.Tls
