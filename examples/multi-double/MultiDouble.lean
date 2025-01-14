import Std.Data.HashMap.Basic

import Curl

open Lean
open Curl

/-
  multi interface code doing two parallel HTTP transfers (see https://curl.se/libcurl/c/multi-double.html
-/

def gather_infos (curlM : HandleM) (curl1 curl2 : Handle) : IO Unit := do
  (← curl_multi_info_read curlM)
  |> Array.forM (fun msg =>
    if msg.easy_handle = curl1 then IO.println s!"handle curl1, result {msg.result}"
    else if msg.easy_handle = curl2 then IO.println s!"handle curl2, result {msg.result}"
    else IO.println "unkown handle")

def main : IO Unit := do
  try
    IO.println s!"curl_version {← curl_version}"

    let curlM ← curl_multi_init

    let r ← IO.mkRef { : IO.FS.Stream.Buffer}
    let curl1 ← curl_easy_init
    curl_set_option curl1 (CurlOption.URL "https://example.com")
    curl_set_option curl1 (CurlOption.WRITEDATA r)
    curl_set_option curl1 (CurlOption.WRITEFUNCTION Curl.writeBytes)
    curl_multi_add_handle curlM curl1

    let r ← IO.mkRef { : IO.FS.Stream.Buffer}
    let curl2 ← curl_easy_init
    curl_set_option curl2 (CurlOption.URL "https://example.com")
    curl_set_option curl2 (CurlOption.WRITEDATA r)
    curl_set_option curl2 (CurlOption.WRITEFUNCTION Curl.writeBytes)
    curl_multi_add_handle curlM curl2

    while (0 < (← curl_multi_perform curlM)) do
      curl_multi_poll curlM 1000
      gather_infos curlM curl1 curl2

    gather_infos curlM curl1 curl2

    curl_multi_remove_handle curlM curl1
    curl_multi_remove_handle curlM curl2

  catch e => IO.println s!"error: {e}"
