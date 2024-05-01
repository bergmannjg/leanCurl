# leanCurl

*leanCurl* is a [Lean 4](https://github.com/leanprover/lean4) package for the [libcurl Easy interface](https://curl.se/libcurl/).

Status:

* compiles with libcurl 7.68.0,
* tested on Ubuntu 20.04 and Windows 11,
* only a few Curl options are implemented, see [Options](https://github.com/bergmannjg/leanCurl/blob/main/src/Curl/Options.lean).

## Installation

Installation steps:

* if curl is installed
  * leanCurl uses the corresponding libcurl shared library 
  * otherwise install curl or the libcurl shared library (see [curl Download](https://curl.se/download.html))
* execute lake update

Lake configuration arguments:

* *libcurlSharedLib*, path to the libcurl shared library,
* *libcurlIncludeDir*, path to the libcurl include directory.

## Examples

Post Json data:

```lean
def main : IO Unit := do
    -- make IO.Ref Stream.Buffer for response data
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}

    -- perfom the network transfer 
    curl_easy_perform_with_options #[
        -- set Url
        CurlOption.URL "https://dummyjson.com/products/add",
        -- set HTTP POST data
        CurlOption.COPYPOSTFIELDS "{\"title\": \"curl\"}",
        -- set HttpHeader
        CurlOption.HTTPHEADER #["Content-Type: application/json", "Accept: application/json"],
        -- response data should be written to this buffer
        CurlOption.WRITEDATA response,
        CurlOption.WRITEFUNCTION Curl.writeBytes
    ]

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

* [httpget](https://github.com/bergmannjg/leanCurl/tree/main/examples/httpget/)
* [httppost](https://github.com/bergmannjg/leanCurl/tree/main/examples/httppost/)
* [httpput](https://github.com/bergmannjg/leanCurl/tree/main/examples/httpput/)
* [httpdelete](https://github.com/bergmannjg/leanCurl/tree/main/examples/httpdelete/)
* [ftpget](https://github.com/bergmannjg/leanCurl/tree/main/examples/ftpget//)
* [reservoir-index](https://github.com/bergmannjg/leanCurl/tree/main/examples/reservoir-index//)
