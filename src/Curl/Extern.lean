import Curl.CurlM

/-! Foreign functions -/

namespace Curl

opaque Handle : Type := Unit

namespace Extern

@[extern "lean_curl_version"]
opaque curl_version : EIO UInt32 String

@[extern "lean_curl_easy_init"]
opaque curl_easy_init : EIO UInt32  Handle

@[extern "lean_curl_easy_perform"]
opaque curl_easy_perform (h : @& Handle) : EIO UInt32 Unit

@[extern "lean_curl_easy_setopt_long"]
opaque curl_easy_setopt_long (h : @& Handle) (opt: UInt32) (v: UInt64) : EIO UInt32 Unit

@[extern "lean_curl_easy_setopt_string"]
opaque curl_easy_setopt_string (h : @& Handle) (opt: UInt32) (str: String) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_strings"]
opaque curl_easy_setopt_strings (h : @& Handle) (opt: UInt32) (strings: Array String) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_headerfunction"]
opaque curl_easy_setopt_headerfunction (h : @& Handle) (f: IO.Ref IO.FS.Stream.Buffer -> ByteArray -> BaseIO Unit) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_headerdata"]
opaque curl_easy_setopt_headerdata (h : @& Handle) (r: IO.Ref IO.FS.Stream.Buffer) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_writefunction"]
opaque curl_easy_setopt_writefunction (h : @& Handle) (f: IO.Ref IO.FS.Stream.Buffer -> ByteArray -> BaseIO Unit) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_writedata"]
opaque curl_easy_setopt_writedata (h : @& Handle) (r: IO.Ref IO.FS.Stream.Buffer) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_readfunction"]
opaque curl_easy_setopt_readfunction (h : @& Handle) (f: IO.Ref IO.FS.Stream.Buffer -> UInt32 -> BaseIO ByteArray) : EIO UInt32  Unit

@[extern "lean_curl_easy_setopt_readdata"]
opaque curl_easy_setopt_readdata (h : @& Handle) (r: IO.Ref IO.FS.Stream.Buffer) : EIO UInt32  Unit

end Curl.Extern
