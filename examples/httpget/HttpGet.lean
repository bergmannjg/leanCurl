import Curl

open Lean
open Curl

/-
  load file https://github.com/leanprover/lean4/archive/refs/tags/v4.0.0.tar.gz via http
-/

def main : IO Unit := do
  try
    IO.println s!"curl_version {← curl_version}"

    -- Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    let curl ← curl_easy_init
    curl_set_option curl (CurlOption.URL "https://github.com/leanprover/lean4/archive/refs/tags/v4.0.0.tar.gz")
    curl_set_option curl (CurlOption.VERBOSE 1)
    if System.Platform.isWindows then curl_set_option curl (CurlOption.CAINFO "C:\\Program Files\\Curl\\bin\\curl-ca-bundle.crt")
    curl_set_option curl (CurlOption.FOLLOWLOCATION 1)
    curl_set_option curl (CurlOption.HTTPHEADER #["application/x-gzip"])
    curl_set_option curl (CurlOption.WRITEDATA response)
    curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
    curl_easy_perform curl

    let bytes ← response.get
    IO.println s!"response: {bytes.data.size} bytes"

  catch e => IO.println s!"error: {e}"
