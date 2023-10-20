/-! Curl options -/

namespace Curl

open Lean

/-- curl options, see: https://curl.se/libcurl/c/curl_easy_setopt.html -/
inductive CurlOption  where
  /-- The full URL to get/put -/
  | URL : String → CurlOption
  /-- user:password;options" to use when fetching. -/
  | USERPWD : String → CurlOption
  /-- Set the User-Agent string (examined by some CGIs) -/
  | USERAGENT : String → CurlOption
  /-- Set the referrer page (needed by some CGIs) -/
  | REFERER : String → CurlOption
  /-- POST static input fields. -/
  | COPYPOSTFIELDS : String → CurlOption
  /-- This points to a linked list of headers. -/
  | HTTPHEADER : Array String → CurlOption
  /-- The internal or given HeaderFunction writes data to this Buffer.
      Without this option data is written to stdout -/
  | HEADERDATA : IO.Ref IO.FS.Stream.Buffer → CurlOption
  /-- Function that will be called to write data to the Buffer. -/
  | HEADERFUNCTION : (IO.Ref IO.FS.Stream.Buffer -> ByteArray -> IO Unit) → CurlOption
  /-- The internal or given WriteFunction writes data to this Buffer.
      Without this option data is written to stdout -/
  | WRITEDATA : IO.Ref IO.FS.Stream.Buffer → CurlOption
  /-- Function that will be called to write data to the Buffer. -/
  | WRITEFUNCTION : (IO.Ref IO.FS.Stream.Buffer -> ByteArray -> IO Unit) → CurlOption
  /-- The internal or given ReadFunction reads data from this Buffer. -/
  | READDATA : IO.Ref IO.FS.Stream.Buffer → CurlOption
  /-- Function that will be called to read data from the Buffer. -/
  | READFUNCTION : (IO.Ref IO.FS.Stream.Buffer -> UInt32 -> IO ByteArray) → CurlOption
  /-- Custom request, for customizing the get command like HTTP: DELETE, TRACE and others. -/
  | CUSTOMREQUEST : String → CurlOption
  /-- talk a lot -/
  | VERBOSE : UInt64 → CurlOption
  /-- use HEAD to get http document -/
  | NOBODY : UInt64 → CurlOption
  /-- this is an upload -/
  | UPLOAD : UInt64 → CurlOption
  /-- bare names when listing directories -/
  | DIRLISTONLY : UInt64 → CurlOption
  /-- follow HTTP 3xx redirects -/
  | FOLLOWLOCATION : UInt64 → CurlOption
  /-- Maximum number of http redirects to follow -/
  | MAXREDIRS : UInt64 → CurlOption
  /-- "name" to use when fetching.  -/
  | USERNAME : String -> CurlOption
  /-- "pwd" to use when fetching.  -/
  | PASSWORD : String -> CurlOption
  /-- set the SSH knownhost file name to use -/
  | SSH_KNOWNHOSTS : String -> CurlOption
