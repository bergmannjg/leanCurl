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

    curl_easy_perform_with_options #[
      CurlOption.URL "https://github.com/leanprover/lean4/archive/refs/tags/v4.0.0.tar.gz",
      CurlOption.VERBOSE 1,
      CurlOption.FOLLOWLOCATION 1,
      CurlOption.HTTPHEADER #["application/x-gzip"],
      CurlOption.WRITEDATA response,
      CurlOption.WRITEFUNCTION Curl.writeBytes
    ]

    let bytes ← response.get
    IO.println s!"response: {bytes.data.size} bytes"

  catch e => IO.println s!"error: {e}"
