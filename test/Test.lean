import Std.Data.HashMap.Basic
import Std.Http.Test.Helpers
import Std.Net.Addr
import Lean.Data.Json

import Curl

open Std.Async
open Std Http Internal Test
open Std.Net
open Lean
open Curl

def checkStatus (l : List HeaderData) (name : String) : IO Unit :=
  let status :=  l.head? |> Option.map (·.status) |>.getD 500
  unless status = 200 do throw (IO.Error.userError s!"HeaderData: {name} status 200 expected, got {status}")


def putShouldContain (s : String) (verbose : Bool) : IO Unit := do
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  let h ← IO.mkRef { : IO.FS.Stream.Buffer}

  let buffer : IO.FS.Stream.Buffer := {data := String.toUTF8 ("{\"title\": \"" ++ s ++ "\"}"), pos := 0}
  let upload ← IO.mkRef buffer

  let version ← curl_version
  if verbose then IO.println s!"curl version {version}"

  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.URL "https://dummyjson.com/products/1")
  curl_set_option curl (CurlOption.VERBOSE 0)
  if System.Platform.isWindows then curl_set_option curl (CurlOption.CAINFO "C:\\Program Files\\Curl\\bin\\curl-ca-bundle.crt")
  curl_set_option curl (CurlOption.UPLOAD 1)
  curl_set_option curl (CurlOption.READDATA upload)
  curl_set_option curl (CurlOption.READFUNCTION Curl.readBytes)
  curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json"])
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)
  curl_easy_perform curl

  let headers := String.fromUTF8! (← h.get).data
  let headerdata := Curl.getHeaderData headers
  checkStatus headerdata "put_should_contain"
  if verbose then IO.println s!"headerdata.length: {headerdata.length}"
  if verbose then List.forM headerdata (fun hd => IO.println s!"headerdata: {hd.version} {hd.status} fields {hd.fields.length}")
  let response := String.fromUTF8! (← r.get).data
  if verbose then IO.println s!"response: {response.length} length"
  let contains := (response.splitOn s).length == 2
  unless contains do throw (IO.Error.userError s!"put_should_contain: '{s}' not found in response")

def getShouldBeEqual (url : String) (file : String) (verbose : Bool) : IO Unit := do
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
  checkStatus headerdata "get_should_be_equal"
  if verbose then IO.println s!"headerdata.length: {headerdata.length}"
  if verbose then List.forM headerdata (fun hd => IO.println s!"headerdata: {hd.version} {hd.status} fields {hd.fields.length}")
  let response := String.fromUTF8! (← r.get).data
  let content ← IO.FS.readFile file

  if verbose then IO.println s!"response: {response.length} bytes, content {content.length} bytes, equal: {response == content}"
  unless response = content do throw (IO.Error.userError s!"get_should_be_equal: expected {content}, got {response}")

def gatherInfos  (verbose : Bool) (curlM : HandleM) : IO Unit := do
  (← curl_multi_info_read curlM)
  |> Array.groupByKey (fun msg => msg.result)
  |> Std.HashMap.toArray
  |> Array.forM (fun (k, v) => do
    if verbose then IO.println s!"result {k}, size {v.size}"
    unless k == ErrorCode.CURLE_OK do throw (IO.Error.userError s!"test_curl_multi: expected {ErrorCode.CURLE_OK}, got {k}"))

def testCurlMulti (n : Nat ) (verbose : Bool) : IO Unit := do
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
    gatherInfos verbose curlM

  gatherInfos verbose curlM
  List.forM curls (fun curl =>  curl_multi_remove_handle curlM curl)

/- serve a curl request with ```handler``` -/
def serveConnection (curl : Handle) (path : String) (handler : Internal.Test.TestHandler) : IO Unit :=
  Async.block do
    let server ← TCP.Socket.Server.mk
    server.bind (SocketAddressV4.mk (.ofParts 127 0 0 1) 0)
    server.listen 128
    server.noDelay
    let addr ← server.getSockName
    let serverTask ← async do
      let conn ← server.accept
      let serveTask ← async (Server.serveConnection conn handler Internal.Test.defaultConfig |>.run)
      await serveTask
      pure ()

    curl_set_option curl (CurlOption.URL s!"http://{addr.ipAddr}:{addr.port}/{path}")
    curl_easy_perform curl

    await serverTask
    pure ()

def testGetRequest (verbose : Bool) : IO Unit := do
  let test := "testGetRequest"
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  let h ← IO.mkRef { : IO.FS.Stream.Buffer}

  let expected := "hallo"
  let handler : TestHandler := fun req =>
    if req.line.method != Method.get then do
      IO.println s!"error: {test} handler, method {Method.get} expected, got {req.line.method}"
      Std.Http.Response.Builder.new |>.status Status.methodNotAllowed |>.text ""
    else Response.ok |>.text expected

  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.VERBOSE 0)
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)

  serveConnection curl "" handler

  let headers := String.fromUTF8! (← h.get).data
  let headerdata := Curl.getHeaderData headers
  checkStatus headerdata test
  if verbose then List.forM headerdata (fun hd => IO.println s!"headerdata: {hd.version} {hd.status} fields {hd.fields.length}")
  let response := String.fromUTF8! (← r.get).data
  if verbose then IO.println s!"response: {response}"
  unless response = expected do
    throw (IO.Error.userError s!"{test}: {expected} expected, got {response}")

structure Product where
  title : String
  deriving ToJson

def testPostRequest (verbose : Bool) : IO Unit := do
  let test := "testPostRequest"
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  let h ← IO.mkRef { : IO.FS.Stream.Buffer}

  let product : Product := {title := "curl"}
  let handler : TestHandler := fun req =>
    if req.line.method != Method.post then do
      IO.println s!"error: {test} handler, method {Method.post} expected, got {req.line.method}"
      Std.Http.Response.Builder.new |>.status Status.methodNotAllowed |>.text ""
    else if ¬req.line.headers.hasEntry Header.Name.contentType (Header.Value.ofString! "application/json")
    then do
      IO.println s!"error: {test} handler, contentType header application/json not found"
      Std.Http.Response.Builder.new |>.status Status.notAcceptable |>.text ""
    else do
      match Lean.Json.parse (← req.body.readAll) with
      | .ok json => Response.ok |>.json json.compress
      | .error _ => Std.Http.Response.Builder.new |>.status Status.unprocessableEntity |>.text ""

  let json := (toJson product).compress
  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.VERBOSE 0)
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.COPYPOSTFIELDS json)
  curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json"])

  serveConnection curl "" handler

  let headers := String.fromUTF8! (← h.get).data
  let headerdata := Curl.getHeaderData headers
  checkStatus headerdata test
  if verbose then List.forM headerdata (fun hd => IO.println s!"headerdata: {hd.version} {hd.status} fields {hd.fields.length}")
  let response := String.fromUTF8! (← r.get).data
  if verbose then IO.println s!"response: {response}"
  unless response = json do
    throw (IO.Error.userError s!"{test}: {json} expected, got {response}")

def main (args : List String) : IO UInt32 := do
  try
    let verbose := args.contains "--verbose"
    IO.println s!"lean version {Lean.versionString}"
    let tests : List (String × (Bool → IO Unit)) := [
      ("getShouldBeEqual", getShouldBeEqual "https://raw.githubusercontent.com/leanprover/lean4/v4.0.0/RELEASES.md" "test/fixtures/lean4_v4.0.0_RELEASES.md"),
      ("putShouldContain", putShouldContain "curl"),
      ("testCurlMulti", testCurlMulti 10),
      ("testGetRequest", testGetRequest),
      ("testPostRequest", testPostRequest)
    ]
    let r ← tests |> List.mapM (fun (name , app) =>
      try app verbose; IO.println s!"test passed: {name} "; pure 0
      catch e => IO.println s!"error: {e}"; pure 1)
    let failures := r.sum
    IO.println s!"tests passed {tests.length - failures}, failures {failures}"
    pure (if failures = 0 then 0 else 1)
  catch e =>
    IO.println s!"error: {e}"
    pure 1
