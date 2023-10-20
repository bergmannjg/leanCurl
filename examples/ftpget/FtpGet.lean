import Lean.Data.Json
import Curl

open Lean
open Curl

/-
  load file via sftp

  gather SSH public keys from test.rebex.net: ssh-keyscan test.rebex.net >> ~/.ssh/known_hosts

  libcurl only accepts connections with hosts that are known and present in ~/.ssh/known_hosts
-/

def main : IO Unit := do
  try
    IO.println s!"curl_version {← curl_version}"

    -- Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    let curl ← curl_easy_init
    curl_set_option curl (CurlOption.URL "sftp://test.rebex.net/readme.txt")
    curl_set_option curl (CurlOption.USERPWD "demo:password")
    curl_set_option curl (CurlOption.VERBOSE 1)
    curl_set_option curl (CurlOption.WRITEDATA response)
    curl_easy_perform curl

    let bytes ← response.get
    IO.println s!"response: date.size {bytes.data.size} bytes"

  catch e => IO.println s!"error: {e}"