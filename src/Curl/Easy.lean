import Curl.Options
import Curl.Extern
import Curl.CurlM

open Lean

/-! Curl Easy interface -/

namespace Curl

/-- default CurlOption.WRITEFUNCTION -/
def writeBytes (r : IO.Ref IO.FS.Stream.Buffer) (bytes : ByteArray) : BaseIO Unit :=
  -- see IO.FS.Stream.ofBuffer
  r.modify fun b =>
    { b with data := bytes.copySlice 0 b.data b.pos bytes.size false, pos := b.pos + bytes.size }

/-- default CurlOption.HEADERFUNCTION -/
def readBytes (r : IO.Ref IO.FS.Stream.Buffer) (n : UInt32) : BaseIO ByteArray :=
  -- see IO.FS.Stream.ofBuffer
  r.modifyGet fun b =>
    let n' := if b.pos + n.toNat < b.data.size then n.toNat else b.data.size - b.pos
    let data := b.data.extract b.pos (b.pos + n')
    (data, { b with pos := b.pos + data.size })

private def toInitError (act : EIO UInt32 α) : EIO Curl.Error α :=
  fun s => match act s with
  | EStateM.Result.error e s => EStateM.Result.error (Curl.Error.init e) s
  | EStateM.Result.ok v s => EStateM.Result.ok v s

private def toOptError (act : EIO UInt32 α) (opt : UInt32) : EIO Curl.Error α :=
  fun s => match act s with
  | EStateM.Result.error e s => EStateM.Result.error (Curl.Error.setopt e opt) s
  | EStateM.Result.ok v s => EStateM.Result.ok v s

private def toPerformError (act : EIO UInt32 α) : EIO Curl.Error α :=
  fun s => match act s with
  | EStateM.Result.error e s => EStateM.Result.error (Curl.Error.perform e) s
  | EStateM.Result.ok v s => EStateM.Result.ok v s

/-- Get curl version -/
def curl_version : EIO Curl.Error String :=
  toInitError Extern.curl_version

/-- Start a libcurl easy session -/
def curl_easy_init : CurlIO Handle :=
  toInitError Extern.curl_easy_init

/-- Set curl option -/
def curl_set_option (curl: Curl.Handle) (opt : CurlOption) : CurlIO Unit := do
  --curl opt types
  let lp : UInt32 := 0
  let sp : UInt32 := 10000
  let fp : UInt32 := 20000

  match opt with
  | CurlOption.URL s => toOptError (Extern.curl_easy_setopt_string curl (sp + 2) s) (sp + 2)
  | CurlOption.USERPWD s => toOptError (Extern.curl_easy_setopt_string curl (sp + 5) s) (sp + 5)
  | CurlOption.WRITEDATA r => toOptError (Extern.curl_easy_setopt_writedata curl r) (sp + 1)
  | CurlOption.WRITEFUNCTION r =>  toOptError (Extern.curl_easy_setopt_writefunction curl r) (fp + 11)
  | CurlOption.HEADERDATA r => toOptError (Extern.curl_easy_setopt_headerdata curl r) (sp + 29)
  | CurlOption.HEADERFUNCTION r =>  toOptError (Extern.curl_easy_setopt_headerfunction curl r) (fp + 79)
  | CurlOption.READDATA r => toOptError (Extern.curl_easy_setopt_readdata curl r) (sp + 9)
  | CurlOption.READFUNCTION r =>  toOptError (Extern.curl_easy_setopt_readfunction curl r) (fp + 12)
  | CurlOption.REFERER s => toOptError (Extern.curl_easy_setopt_string curl (sp + 16) s) (sp + 16)
  | CurlOption.USERAGENT s => toOptError (Extern.curl_easy_setopt_string curl (sp + 18) s) (sp + 18)
  | CurlOption.HTTPHEADER strings => toOptError (Extern.curl_easy_setopt_strings curl (sp + 23) strings) (sp + 23)
  | CurlOption.CUSTOMREQUEST s => toOptError (Extern.curl_easy_setopt_string curl (sp + 36) s) (sp + 36)
  | CurlOption.VERBOSE v => toOptError (Extern.curl_easy_setopt_long curl (lp + 41) v) (lp + 41)
  | CurlOption.NOBODY v => toOptError (Extern.curl_easy_setopt_long curl (lp + 44) v) (lp + 44)
  | CurlOption.UPLOAD v => toOptError (Extern.curl_easy_setopt_long curl (lp + 46) v) (lp + 46)
  | CurlOption.DIRLISTONLY v => toOptError (Extern.curl_easy_setopt_long curl (lp + 48) v) (lp + 48)
  | CurlOption.FOLLOWLOCATION v => toOptError (Extern.curl_easy_setopt_long curl (lp + 52) v) (lp + 52)
  | CurlOption.SSL_VERIFYPEER v => toOptError (Extern.curl_easy_setopt_long curl (lp + 64) v) (lp + 64)
  | CurlOption.CAINFO v => toOptError (Extern.curl_easy_setopt_string curl (sp + 65) v) (lp + 65)
  | CurlOption.MAXREDIRS v => toOptError (Extern.curl_easy_setopt_long curl (lp + 68) v) (lp + 68)
  | CurlOption.COPYPOSTFIELDS s => toOptError (Extern.curl_easy_setopt_string curl (sp + 165) s) (sp + 165)
  | CurlOption.USERNAME s => toOptError (Extern.curl_easy_setopt_string curl (sp + 173) s)  (sp + 173)
  | CurlOption.PASSWORD s => toOptError (Extern.curl_easy_setopt_string curl (sp + 174) s)  (sp + 174)
  | CurlOption.SSH_KNOWNHOSTS s => toOptError (Extern.curl_easy_setopt_string curl (sp + 183) s) (sp + 183)

/-- Perform a network transfer -/
def curl_easy_perform (h : Handle) : CurlIO Unit :=
  toPerformError (Extern.curl_easy_perform h)
