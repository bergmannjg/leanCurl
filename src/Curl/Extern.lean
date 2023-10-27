import Curl.CurlM

/-! Foreign functions -/

namespace Curl

/- todo: doesn't work in windows 11
@[export lean_mk_curl_error_init_error]
def mkInitError : UInt32 → Curl.Error :=
  Curl.Error.init

@[export lean_mk_curl_error_setopt_error]
def mkSetoptError : UInt32 → UInt32 → Curl.Error :=
  Curl.Error.setopt

@[export lean_mk_curl_error_perform_error]
def mkPerformError : UInt32 → Curl.Error :=
  Curl.Error.perform
-/

opaque Handle : Type := Unit

namespace Extern

@[extern "lean_curl_version"]
opaque curl_version : CurlIO String

@[extern "lean_curl_easy_init"]
opaque curl_easy_init : CurlIO Handle

@[extern "lean_curl_easy_perform"]
opaque curl_easy_perform (h : @& Handle) : CurlIO Unit

@[extern "lean_curl_easy_setopt_long"]
opaque curl_easy_setopt_long (h : @& Handle) (opt: UInt32) (v: UInt64) : CurlIO Unit

@[extern "lean_curl_easy_setopt_string"]
opaque curl_easy_setopt_string (h : @& Handle) (opt: UInt32) (str: String) : CurlIO Unit

@[extern "lean_curl_easy_setopt_strings"]
opaque curl_easy_setopt_strings (h : @& Handle) (opt: UInt32) (strings: Array String) : CurlIO Unit

@[extern "lean_curl_easy_setopt_headerfunction"]
opaque curl_easy_setopt_headerfunction (h : @& Handle) (f: IO.Ref IO.FS.Stream.Buffer -> ByteArray -> BaseIO Unit) : CurlIO Unit

@[extern "lean_curl_easy_setopt_headerdata"]
opaque curl_easy_setopt_headerdata (h : @& Handle) (r: IO.Ref IO.FS.Stream.Buffer) : CurlIO Unit

@[extern "lean_curl_easy_setopt_writefunction"]
opaque curl_easy_setopt_writefunction (h : @& Handle) (f: IO.Ref IO.FS.Stream.Buffer -> ByteArray -> BaseIO Unit) : CurlIO Unit

@[extern "lean_curl_easy_setopt_writedata"]
opaque curl_easy_setopt_writedata (h : @& Handle) (r: IO.Ref IO.FS.Stream.Buffer) : CurlIO Unit

@[extern "lean_curl_easy_setopt_readfunction"]
opaque curl_easy_setopt_readfunction (h : @& Handle) (f: IO.Ref IO.FS.Stream.Buffer -> UInt32 -> BaseIO ByteArray) : CurlIO Unit

@[extern "lean_curl_easy_setopt_readdata"]
opaque curl_easy_setopt_readdata (h : @& Handle) (r: IO.Ref IO.FS.Stream.Buffer) : CurlIO Unit

end Curl.Extern
