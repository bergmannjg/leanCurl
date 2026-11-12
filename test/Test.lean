import Std.Data.HashMap.Basic

import Curl

open Lean
open Curl

def put_should_contain (s : String) : IO Unit := do
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}

  let buffer : IO.FS.Stream.Buffer := {data := String.toUTF8 ("{\"title\": \"" ++ s ++ "\"}"), pos := 0}
  let upload ← IO.mkRef buffer

  let version ← curl_version
  IO.println s!"curl version {version}"

  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.URL "https://dummyjson.com/products/1")
  curl_set_option curl (CurlOption.VERBOSE 0)
  if System.Platform.isWindows then curl_set_option curl (CurlOption.CAINFO "C:\\Program Files\\Curl\\bin\\curl-ca-bundle.crt")
  curl_set_option curl (CurlOption.UPLOAD 1)
  curl_set_option curl (CurlOption.READDATA upload)
  curl_set_option curl (CurlOption.READFUNCTION Curl.readBytes)
  curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json", "Accept: application/json"])
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_easy_perform curl

  let response := String.fromUTF8! (← r.get).data
  IO.println s!"response: {response.length} length, contains '{s}': {(response.splitOn s).length == 2}"

def get_should_be_equal (url : String) (file : String) : IO Unit := do
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  let h ← IO.mkRef { : IO.FS.Stream.Buffer}

  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.URL url)
  curl_set_option curl (CurlOption.VERBOSE 0)
  if System.Platform.isWindows then curl_set_option curl (CurlOption.CAINFO "C:\\Program Files\\Curl\\bin\\curl-ca-bundle.crt")
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)
  curl_easy_perform curl

  let headers := String.fromUTF8! (← h.get).data
  let headerdata := Curl.getHeaderData headers
  IO.println s!"headerdata.length: {headerdata.length}"
  List.forM headerdata (fun hd => IO.println s!"headerdata: {hd.version} {hd.status} fields {hd.fields.length}")
  let response := String.fromUTF8! (← r.get).data
  let content ← IO.FS.readFile file

  IO.println s!"response: {response.length} bytes, content {content.length} bytes, equal: {response == content}"

def gather_infos (curlM : HandleM) : IO Unit := do
  (← curl_multi_info_read curlM)
  |> Array.groupByKey (fun msg => msg.result)
  |> Std.HashMap.toArray
  |> Array.forM (fun (k, v) => IO.println s!"result {k}, size {v.size}")

def test_curl_multi (n : Nat ): IO Unit := do
  let curlM ← curl_multi_init

  let curls ←
    List.range n
    |> List.mapM (fun _ => do
        let r ← IO.mkRef { : IO.FS.Stream.Buffer}
        let curl ← curl_easy_init
        curl_set_option curl (CurlOption.URL "https://example.com")
        curl_set_option curl (CurlOption.WRITEDATA r)
        curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
        curl_multi_add_handle curlM curl
        pure curl)

  while (0 < (← curl_multi_perform curlM)) do
    curl_multi_poll curlM 1000
    gather_infos curlM

  gather_infos curlM
  List.forM curls (fun curl =>  curl_multi_remove_handle curlM curl)

open scoped Curl.Tls in
/-- Curl.Tls: a self-signed certificate, one connection served over https on the loopback, fetched by
libcurl with that certificate as its CA. -/
def tls_round_trip : IO Unit := do
  let dir := "build/tls-test"
  IO.FS.createDirAll dir
  let cert := s!"{dir}/cert.pem"; let key := s!"{dir}/key.pem"
  Curl.Tls.selfSigned "localhost" "IP:127.0.0.1,DNS:localhost" 1 cert key
  let ctx ← Curl.Tls.serverContext cert key
  let l ← Curl.Tls.listen "127.0.0.1" 0
  let server ← IO.asTask do
    let c ← Curl.Tls.accept ctx l
    let request ← Curl.Tls.read c
    Curl.Tls.write c "HTTP/1.0 200 OK\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello".toUTF8
    Curl.Tls.close c
    pure (String.fromUTF8! request)
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  curl_easy_perform_with_options #[
    CurlOption.URL s!"https://127.0.0.1:{l.port}/",
    CurlOption.CAINFO cert,
    CurlOption.WRITEDATA r,
    CurlOption.WRITEFUNCTION Curl.writeBytes]
  let buf ← r.get
  let body := String.fromUTF8! (buf.data.extract 0 buf.pos)
  let request ← IO.ofExcept (← IO.wait server)
  IO.println s!"tls round trip over https: body is 'hello': {body == "hello"}, the server saw 'GET / HTTP/1.1': {request.startsWith "GET / HTTP/1.1"}"

def main : IO Unit := do
  try
    tls_round_trip
    IO.println s!"lean version {Lean.versionString}"
    get_should_be_equal "https://raw.githubusercontent.com/leanprover/lean4/v4.0.0/RELEASES.md" "test/fixtures/lean4_v4.0.0_RELEASES.md"
    put_should_contain "curl"
    test_curl_multi 10
  catch e => IO.println s!"error: {e}"
