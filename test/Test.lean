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

def main : IO Unit := do
  try
    get_should_be_equal "https://raw.githubusercontent.com/leanprover/lean4/v4.0.0/RELEASES.md" "test/fixtures/lean4_v4.0.0_RELEASES.md"
    put_should_contain "curl"
  catch e => IO.println s!"error: {e}"
