# leanCurl

*leanCurl* is a [Lean 4](https://github.com/leanprover/lean4) package for the [libcurl Easy interface](https://curl.se/libcurl/).

Status:

* compiles with libcurl 7.68.0,
* tested on Ubuntu 20.04,
* only a few Curl options are implemented, see [Options](src/Curl/Options.lean).

## Installation

Installation steps:

* install the libcurl shared library (on Ubuntu e.g. with `apt-get install libcurl4`)
* execute lake build

Lake configuration arguments:

* *libcurlSharedLib*, default is */usr/lib/libcurl.so.4*
* *libcurlIncludeDir*, default is *"native/curl-7.68.0*

## Examples

Post Json data:

```lean
def main : IO Unit := do
    -- make IO.Ref Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    -- init curl handle, leanCurl is responsible for calling curl_easy_cleanup 
    let curl ← curl_easy_init
    -- set Url
    curl_set_option curl (CurlOption.URL "https://dummyjson.com/products/add")
    -- set HTTP POST data
    curl_set_option curl (COPYPOSTFIELDS "{\"title\": \"curl\"}")
    -- set HttpHeader
    curl_set_option curl (CurlOption.HTTPHEADER #["Content-Type: application/json", "Accept: application/json"])
    -- response data should be written to this buffer
    curl_set_option curl (CurlOption.WRITEDATA response)
    -- perfom the network transfer 
    curl_easy_perform curl

    -- get Stream.Buffer of IO.Ref 
    let bytes ← response.get
    IO.println s!"response: {String.fromUTF8Unchecked bytes.data}"

```

Example projects:

* [httpget](examples/httpget/)
* [httppost](examples/httppost/)
* [httpput](examples/httpput/)
* [httpdelete](examples/httpdelete/)
* [ftpget](examples/ftpget//)
