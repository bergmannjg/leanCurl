import Lean.Data.Json
import Curl

open Lean
open Curl

/-
  get json data via http DELETE request
-/

def main : IO Unit := do
  try
    IO.println s!"curl_version {← curl_version}"

    -- Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    let curl ← curl_easy_init
    curl_set_option curl (CurlOption.URL "https://dummyjson.com/products/1")
    curl_set_option curl (CurlOption.CUSTOMREQUEST "DELETE")
    curl_set_option curl (CurlOption.VERBOSE 1)
    curl_set_option curl (CurlOption.HTTPHEADER #["Accept: application/json"])
    curl_set_option curl (CurlOption.WRITEDATA response)
    curl_easy_perform curl

    let bytes ← response.get
    IO.println s!"response: {String.fromUTF8Unchecked bytes.data}"

  catch e => IO.println s!"error: {e}"