import Curl.CurlM
import Curl.Errors

/-! Foreign functions -/

namespace Curl

opaque Handle : Type := Unit

opaque HandleM : Type := Unit

inductive CurlMsgType
  | Done

/-- Message from the individual transfers of multi handle. -/
structure CurlMsg where
  /-- the handle it concerns -/
  easy_handle : Handle
  /-- return code for transfer -/
  result : ErrorCode

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

@[extern "lean_curl_multi_init"]
opaque curl_multi_init : EIO UInt32  HandleM

@[extern "lean_curl_multi_add_handle"]
opaque curl_multi_add_handle (hm : @& HandleM) (h : @& Handle) : EIO UInt32 Unit

@[extern "lean_curl_multi_remove_handle"]
opaque curl_multi_remove_handle (hm : @& HandleM) (h : @& Handle) : EIO UInt32 Unit

@[extern "lean_curl_multi_perform"]
opaque curl_multi_perform (hm : @& HandleM) : EIO UInt32 Int

@[extern "lean_curl_multi_poll"]
opaque curl_multi_poll (hm : @& HandleM) (timeout : Int) : EIO UInt32 Unit

@[extern "lean_curl_multi_info_read"]
opaque curl_multi_info_read (hm : @& HandleM) : EIO UInt32 $ Array CurlMsg

@[extern "lean_curl_handle_dec_eq"]
opaque  Handle.decEq (a b : @& Handle) : Decidable (Eq a b)

instance : DecidableEq Handle := Handle.decEq

@[extern "lean_curl_handlem_dec_eq"]
opaque  HandleM.decEq (a b : @& HandleM) : Decidable (Eq a b)

instance : DecidableEq HandleM := HandleM.decEq

end Curl.Extern
