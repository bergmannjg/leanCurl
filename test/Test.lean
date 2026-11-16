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

def checkInfos (curlM : HandleM) (curlsIdx : List Handle): IO Unit := do
  let infos ← curl_multi_info_read curlM
  unless infos.size = curlsIdx.length do
      throw (IO.Error.userError s!"test_curl_multi: multi_info expected {curlsIdx.length}, got {infos.size}")
  infos
  |> Array.forM (fun msg => do
    unless msg.result == ErrorCode.CURLE_OK do
      throw (IO.Error.userError s!"test_curl_multi: expected {ErrorCode.CURLE_OK}, got {msg.result}"))

/- serve curl requests with ```handler``` -/
def serveConnections (curlM : Option HandleM) (curls : List Handle) (path : String)
  (handler : Internal.Test.TestHandler) : IO Unit :=
  Async.block do
    let tuples ← curls.mapM (fun curl => do
      let server ← TCP.Socket.Server.mk
      server.bind (SocketAddressV4.mk (.ofParts 127 0 0 1) 0)
      server.listen 128
      server.noDelay
      pure (curl, server))
    let serverTasks ← tuples.mapM (fun (_, server) => do
      async do
        let conn ← server.accept
        let serveTask ← async (Server.serveConnection conn handler Internal.Test.defaultConfig |>.run)
        await serveTask)

    tuples.forM (fun (curl, server) => do
      let addr ← server.getSockName
      curl_set_option curl (CurlOption.URL s!"http://{addr.ipAddr}:{addr.port}/{path}")
      match curlM with
      | some curlM => curl_multi_add_handle curlM curl
      | none => curl_easy_perform curl)

    match curlM with
    | some curlM =>
        let mut fuel := 1000
        while (0 < (← curl_multi_perform curlM) && 0 < fuel) do
          curl_multi_poll curlM 1000
          fuel := fuel - 1
        if fuel = 0 then
            throw (IO.Error.userError s!"test_curl_multi: curl_multi_perform timeout")
        checkInfos curlM curls
        List.forM curls (fun curl => curl_multi_remove_handle curlM curl)
    | none => pure ()

    serverTasks.forM MonadAwait.await
    pure ()

def textHandler (test text : String ): TestHandler := fun req =>
    if req.line.method != Method.get then do
      IO.println s!"error: {test} handler, method {Method.get} expected, got {req.line.method}"
      Std.Http.Response.Builder.new |>.status Status.methodNotAllowed |>.text ""
    else Response.ok |>.text text

def jsonHandler (test : String) (method : Method): TestHandler := fun req =>
    if req.line.method != method then do
      IO.println s!"error: {test} handler, method {method} expected, got {req.line.method}"
      Std.Http.Response.Builder.new |>.status Status.methodNotAllowed |>.text ""
    else if ¬req.line.headers.hasEntry Header.Name.contentType (Header.Value.ofString! "application/json")
    then do
      IO.println s!"error: {test} handler, contentType header application/json not found"
      Std.Http.Response.Builder.new |>.status Status.notAcceptable |>.text ""
    else do
      match Lean.Json.parse (← req.body.readAll) with
      | .ok json => Response.ok |>.json json.compress
      | .error _ => Std.Http.Response.Builder.new |>.status Status.unprocessableEntity |>.text ""

def testPutRequest (verbose : Bool) : IO Unit := do
  let test := "testPutRequest"
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  let h ← IO.mkRef { : IO.FS.Stream.Buffer}

  let expected := "curl"
  let buffer : IO.FS.Stream.Buffer := {data := String.toUTF8 ("{\"title\": \"" ++ expected ++ "\"}"), pos := 0}
  let upload ← IO.mkRef buffer

  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.VERBOSE 0)
  curl_set_option curl (CurlOption.UPLOAD 1)
  curl_set_option curl (CurlOption.READDATA upload)
  curl_set_option curl (CurlOption.READFUNCTION Curl.readBytes)
  curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json"])
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)

  serveConnections none [curl] "products/1" (jsonHandler test Method.put)

  let headers := String.fromUTF8! (← h.get).data
  let headerdata := Curl.getHeaderData headers
  checkStatus headerdata "put_should_contain"
  if verbose then List.forM headerdata (fun hd => IO.println s!"headerdata: {hd.version} {hd.status} fields {hd.fields.length}")
  let response := String.fromUTF8! (← r.get).data
  if verbose then IO.println s!"response: {response.length} length"
  let contains := (response.splitOn expected).length == 2
  unless contains do throw (IO.Error.userError s!"put_should_contain: '{expected}' not found in response {response}")

def testCurlMulti (n : Nat ) (verbose : Bool) : IO Unit := do
  let test := "testCurlMulti"
  let curlM ← curl_multi_init

  let pairs ←
    List.range n
    |> List.mapM (fun _ => do
        let r ← IO.mkRef { : IO.FS.Stream.Buffer}
        let curl ← curl_easy_init
        curl_set_option curl (CurlOption.WRITEDATA r)
        curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
        pure (r, curl))

  let expected := "hallo"
  serveConnections curlM (pairs.map (·.snd)) "" (textHandler test expected)

  pairs.forM (fun (r, _) => do
    let response := String.fromUTF8! (← r.get).data
    if verbose then IO.println s!"response: {response}"
    unless response = expected do
      throw (IO.Error.userError s!"{test}: {expected} expected, got {response}"))

def testGetRequest (verbose : Bool) : IO Unit := do
  let test := "testGetRequest"
  let r ← IO.mkRef { : IO.FS.Stream.Buffer}
  let h ← IO.mkRef { : IO.FS.Stream.Buffer}

  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.VERBOSE 0)
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)

  let expected := "hallo"
  serveConnections none [curl] "" (textHandler test expected)

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
  let json := (toJson product).compress
  let curl ← curl_easy_init
  curl_set_option curl (CurlOption.VERBOSE 0)
  curl_set_option curl (CurlOption.WRITEDATA r)
  curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.HEADERDATA h)
  curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)
  curl_set_option curl (CurlOption.COPYPOSTFIELDS json)
  curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json"])

  serveConnections none [curl] "" (jsonHandler test Method.post)

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
      ("testPutRequest", testPutRequest),
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
