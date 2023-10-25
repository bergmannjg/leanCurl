import Lean.Data.Json
import Curl

open Lean
open Curl

/-
  post json data via http POST request
-/

structure Product where
  title : String
  deriving ToJson

def main : IO Unit := do
  try
    IO.println s!"curl_version {← curl_version}"
    let product : Product := {title := "curl"}

    -- Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    let curl ← curl_easy_init
    curl_set_option curl (CurlOption.URL "https://dummyjson.com/products/add")
    curl_set_option curl (CurlOption.VERBOSE 0)
    if System.Platform.isWindows then curl_set_option curl (CurlOption.CAINFO "C:\\Program Files\\Curl\\bin\\curl-ca-bundle.crt")
    curl_set_option curl (CurlOption.COPYPOSTFIELDS (toJson product).compress)
    curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json", "Accept: application/json"])
    curl_set_option curl (CurlOption.WRITEDATA response)
    curl_easy_perform curl

    let bytes ← response.get
    IO.println s!"response: {String.fromUTF8Unchecked bytes.data}"

  catch e => IO.println s!"error: {e}"
