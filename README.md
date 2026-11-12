# leanCurl

[Lean 4](https://github.com/leanprover/lean4) bindings to [libcurl](https://curl.se/libcurl/c/).

Status:

* compiles with libcurl 7.68.0,
* tested on Ubuntu 20.04 and Windows 11,
* built with Lean `v4.35.0` (see [lean-toolchain](./lean-toolchain)),
* the library uses the [Lean module system](https://lean-lang.org/doc/reference/latest/Source-Files-and-Modules/):
  every file under `src/` starts with `module`, so `Curl` can be imported
  from `module` files (`public import Curl`) as well as from classic files (`import Curl`),
* only a few Curl options are implemented, see [Options](https://github.com/bergmannjg/leanCurl/blob/main/src/Curl/Options.lean).

## Installation

Installation steps:

* if curl is installed
  * leanCurl uses the corresponding libcurl shared library 
  * otherwise install curl or the libcurl shared library (see [curl Download](https://curl.se/download.html))
* execute lake update

Lake configuration arguments:

* *libcurlSharedLib*, path to the libcurl shared library,
* *libcurlIncludeDir*, path to the libcurl include directory.

To complile on macOS, you have to reinstall curl (linking to the pre-installed libcurl library doesn't work)

```sh
 brew reinstall curl
 ```

## Examples

Post Json data:

```lean
def main : IO Unit := do
    -- make IO.Ref Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    -- perfom the network transfer 
    curl_easy_perform_with_options #[       
        CurlOption.URL "https://dummyjson.com/products/add", -- set Url        
        CurlOption.COPYPOSTFIELDS "{\"title\": \"curl\"}", -- set HTTP POST data
        CurlOption.HTTPHEADER #["Content-Type: application/json", "Accept: application/json"], -- set HttpHeader       
        CurlOption.WRITEDATA response, -- response data should be written to this buffer
        CurlOption.WRITEFUNCTION Curl.writeBytes
    ]

    -- get Stream.Buffer of IO.Ref 
    let bytes ← response.get
    IO.println s!"response: {String.fromUTF8! bytes.data}"

```

The corresponding curl command is

```sh
curl -d "{\"title\": \"curl\"}" https://dummyjson.com/products/add
```

The [--libcurl](https://everything.curl.dev/libcurl/--libcurl) option displays the correspondence.

Example projects (see [build-examples.sh](./build-examples.sh)):

* [httpget](https://github.com/bergmannjg/leanCurl/tree/main/examples/httpget/)
* [httppost](https://github.com/bergmannjg/leanCurl/tree/main/examples/httppost/)
* [httpput](https://github.com/bergmannjg/leanCurl/tree/main/examples/httpput/)
* [httpdelete](https://github.com/bergmannjg/leanCurl/tree/main/examples/httpdelete/)
* [ftpget](https://github.com/bergmannjg/leanCurl/tree/main/examples/ftpget//)
* [multi-double](https://github.com/bergmannjg/leanCurl/tree/main/examples/multi-double/)
* [reservoir-index](https://github.com/bergmannjg/leanCurl/tree/main/examples/reservoir-index//)

## TLS server

`Curl.Tls` is the other side of libcurl, for tests and mocks served over https on the loopback: a
listening socket, a server context from a certificate and its key, connections accepted, read and
written, and a self-signed certificate made on the spot (OpenSSL). Link with `-lssl -lcrypto`.

```lean
open scoped Curl.Tls in
def main : IO Unit := do
    Curl.Tls.selfSigned "localhost" "IP:127.0.0.1,DNS:localhost" 1 "cert.pem" "key.pem"
    let ctx ← Curl.Tls.serverContext "cert.pem" "key.pem"
    let l ← Curl.Tls.listen "127.0.0.1" 8443   -- Curl.Tls.port l; closed when dropped or by closeListener
    let c ← Curl.Tls.accept ctx l            -- the handshake done
    let request ← Curl.Tls.read c            -- bytes; empty once the peer has closed
    Curl.Tls.write c "HTTP/1.0 200 OK\r\nContent-Length: 5\r\n\r\nhello".toUTF8
    Curl.Tls.close c
```

### The protocol, as types and as a model

`Curl.Tls.withConnection ctx l body` accepts one connection, hands `body` an `Open` handle whose only
operations are `Open.read` and `Open.write`, and closes the connection when `body` ends, by return or by
error. A program that touches connections only through `withConnection` cannot read or write a closed
one: `Open` has no `close`, and only `withConnection` makes an `Open`.

`Curl.Tls.Protocol` is the same protocol as a model: `Cmd` the calls, `step` which ones the shim answers
and which it refuses ("connection closed", "listener closed"), `run` a trace. Theorems:
`read_after_close_stuck`, `write_after_close_stuck`, `accept_after_closeListener_stuck`, `close_idem`,
`closeListener_idem`, and `withConnection_runs` — on a listening state, the trace of `withConnection`
with any body runs with no stuck call and ends with the connection closed. These are about programs
written against the shim's contract (which `lake exe test` checks); they say nothing about OpenSSL.

### Concurrency

Every `Curl.Tls` call blocks the calling thread until the kernel or OpenSSL answers (`accept` until a
client connects and its handshake ends, `read` until bytes or the peer's close arrive). Run a serving
loop in a task of its own, `IO.asTask … Task.Priority.dedicated`, so it does not hold one of Lean's
pool threads; `Task.spawn`/plain `IO.asTask` are for short work.

What may be shared between tasks and what may not:

* a `Context` may be shared: `accept` on it from several tasks at once is safe (OpenSSL's `SSL_CTX` is
  read-only after `serverContext`);
* a `Listener` may be shared: several tasks may `accept` on the same listener, each connection goes to
  exactly one of them (the kernel's `accept(2)` guarantee);
* a `Connection` belongs to one task at a time: a TLS session (`SSL`) has state that two concurrent
  `read`/`write` calls corrupt. Hand it over, do not share it;
* initialisation (OpenSSL, the external classes, SIGPIPE) runs once, under `pthread_once`, whichever
  task comes first;
* `Curl.Tls` sets `SIGPIPE` to ignored for the whole process at first use, so writing to a peer that
  has gone makes `write` fail with a message instead of ending the program. If the program relies on
  `SIGPIPE`, do not use `Curl.Tls` in it.

Lifetimes: a `Listener` closes its socket when dropped or at `closeListener`; a `Connection` closes at
`close` or when dropped; `close`/`closeListener` are idempotent; `read`/`write` after `close` and
`accept` after `closeListener` fail with a message (never a crash). Errors are `EIO String`, the
message OpenSSL's or `strerror`'s.

### The TLS flow and what is verified

The protocol is OpenSSL's: TLS 1.3 ([RFC 8446](https://www.rfc-editor.org/rfc/rfc8446)) or TLS 1.2
([RFC 5246](https://www.rfc-editor.org/rfc/rfc5246)), never below 1.2 (`SSL_CTX_set_min_proto_version`),
cipher suites and the exact ceiling from the system's `openssl.cnf`. Certificates are X.509 v3
([RFC 5280](https://www.rfc-editor.org/rfc/rfc5280)).

*Server* (`serverContext`, `accept`): presents one certificate chain (the file may hold the leaf and its
intermediates) and signs with its key; checks nothing about the client (`SSL_VERIFY_NONE` — no client
certificates, no SNI dispatch: one certificate for every name). A connection whose handshake fails is
an `accept` error and the listener goes on. `selfSigned` makes the test certificate as `openssl req
-x509` does: version 3, `subjectAltName` from the `san` argument (`IP:…`, `DNS:…`),
`basicConstraints critical,CA:TRUE`, a key identifier, RSA-2048, SHA-256, serial = creation time;
the key is written mode 0600, the certificate 0644.

*Client* (libcurl, the rest of this library): verifies the server as RFC 5280 §6.1 path validation by
OpenSSL, with the trust anchors from `CAINFO` (a self-signed certificate given there is its own anchor
— the test's case) or the system store, then matches the host of the URL against the certificate's
`subjectAltName` as [RFC 6125](https://www.rfc-editor.org/rfc/rfc6125) §6.4 describes (an IP literal
against `IP:` entries, a name against `DNS:` entries, wildcards per §6.4.3). `SSL_VERIFYPEER 0` turns
the first check off — for a throwaway test only; hostname matching cannot be turned off from Lean (no
`SSL_VERIFYHOST` option is exposed, on purpose). Mutual TLS is not offered.

What is *verified* here and how:

* by test (`lake exe test`, `tls_round_trip`): the certificate is made, a connection served, fetched by
  libcurl with that certificate as its anchor, the key's mode 600, `accept` after `closeListener` refused;
* by construction in Lean: the API's types — `Context`, `Listener`, `Connection` are opaque, every
  operation is in `TlsIO`, so nothing but these functions touches the native state;
* **trusted, not verified**: OpenSSL (handshake, record layer, path validation), libcurl (hostname
  matching), the C shim `native/leantls.cpp` (≈250 lines, reviewed), the Lean runtime's external
  objects. No Lean theorem speaks about these, and none should be read as doing so.
