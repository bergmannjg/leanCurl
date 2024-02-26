# leanCurl

*leanCurl* is a [Lean 4](https://github.com/leanprover/lean4) package for the [libcurl Easy interface](https://curl.se/libcurl/).

Status:

* compiles with libcurl 7.68.0,
* tested on Ubuntu 20.04 and Windows 11,
* only a few Curl options are implemented, see [Options](src/Curl/Options.lean).

## Installation

Installation steps:

* install the libcurl shared library (see [curl Download](https://curl.se/download.html))
* execute lake build

Lake configuration arguments:

* *libcurlSharedLib*, path to the libcurl shared library,
* *libcurlIncludeDir*, path to the libcurl include directory.

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
    curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
    -- perfom the network transfer 
    curl_easy_perform curl

    -- get Stream.Buffer of IO.Ref 
    let bytes ← response.get
    IO.println s!"response: {String.fromUTF8Unchecked bytes.data}"

```

The corresponding curl command is

```sh
curl -d "{\"title\": \"curl\"}" https://dummyjson.com/products/add
```

The [--libcurl](https://everything.curl.dev/libcurl/libcurl) option displays the correspondence.

Example projects:

* [httpget](examples/httpget/)
* [httppost](examples/httppost/)
* [httpput](examples/httpput/)
* [httpdelete](examples/httpdelete/)
* [ftpget](examples/ftpget//)
