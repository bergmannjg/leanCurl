import Curl.Options
import Curl.Extern

open Lean

/-! Curl Easy interface -/

namespace Curl

private def writeBytes (r : IO.Ref IO.FS.Stream.Buffer) (bytes : ByteArray) : IO Unit :=
  -- see IO.FS.Stream.ofBuffer  
  r.modify fun b =>
    { b with data := bytes.copySlice 0 b.data b.pos bytes.size false, pos := b.pos + bytes.size }

private def readBytes (r : IO.Ref IO.FS.Stream.Buffer) (n : UInt32) : IO ByteArray :=
  -- see IO.FS.Stream.ofBuffer  
  r.modifyGet fun b =>
    let n' := if b.pos + n.toNat < b.data.size then n.toNat else b.data.size - b.pos
    let data := b.data.extract b.pos (b.pos + n')
    (data, { b with pos := b.pos + data.size })

/-- Get curl version -/
def curl_version : IO String := Extern.curl_version

/-- Start a libcurl easy session -/
def curl_easy_init : IO Handle := Extern.curl_easy_init

/-- Set curl option -/
def curl_set_option (curl: Curl.Handle) (opt : CurlOption) : IO Unit := do
  --curl opt types
  let lp : UInt32 := 0
  let sp : UInt32 := 10000

  match opt with
  | CurlOption.URL s => pure (← Extern.curl_easy_setopt_string curl (sp + 2) s)
  | CurlOption.USERPWD s => pure (← Extern.curl_easy_setopt_string curl (sp + 5) s)
  | CurlOption.WRITEDATA r => do
      Extern.curl_easy_setopt_writedata curl r 
      Extern.curl_easy_setopt_writefunction curl writeBytes -- set default writefunction
      pure ()
  | CurlOption.WRITEFUNCTION r =>  pure (← Extern.curl_easy_setopt_writefunction curl r)
  | CurlOption.HEADERDATA r => do
      Extern.curl_easy_setopt_headerdata curl r 
      Extern.curl_easy_setopt_headerfunction curl writeBytes -- set default writefunction
      pure ()
  | CurlOption.HEADERFUNCTION r =>  pure (← Extern.curl_easy_setopt_headerfunction curl r)
  | CurlOption.READDATA r =>  
      Extern.curl_easy_setopt_readdata curl r 
      Extern.curl_easy_setopt_readfunction curl readBytes -- set default readfunction
      pure ()
  | CurlOption.READFUNCTION r =>  pure (← Extern.curl_easy_setopt_readfunction curl r)
  | CurlOption.REFERER s => pure (← Extern.curl_easy_setopt_string curl (sp + 16) s)
  | CurlOption.USERAGENT s => pure (← Extern.curl_easy_setopt_string curl (sp + 18) s)
  | CurlOption.HTTPHEADER strings => pure (← Extern.curl_easy_setopt_strings curl (sp + 23) strings)
  | CurlOption.CUSTOMREQUEST s => pure (← Extern.curl_easy_setopt_string curl (sp + 36) s)
  | CurlOption.VERBOSE v => pure (← Extern.curl_easy_setopt_long curl (lp + 41) v)
  | CurlOption.NOBODY v => pure (← Extern.curl_easy_setopt_long curl (lp + 44) v)
  | CurlOption.UPLOAD v => pure (← Extern.curl_easy_setopt_long curl (lp + 46) v)
  | CurlOption.DIRLISTONLY v => pure (← Extern.curl_easy_setopt_long curl (lp + 48) v)
  | CurlOption.FOLLOWLOCATION v => pure (← Extern.curl_easy_setopt_long curl (lp + 52) v)
  | CurlOption.MAXREDIRS v => pure (← Extern.curl_easy_setopt_long curl (lp + 68) v)
  | CurlOption.COPYPOSTFIELDS s => pure (← Extern.curl_easy_setopt_string curl (sp + 165) s)
  | CurlOption.USERNAME s => pure (← Extern.curl_easy_setopt_string curl (sp + 173) s)
  | CurlOption.PASSWORD s => pure (← Extern.curl_easy_setopt_string curl (sp + 174) s)
  | CurlOption.SSH_KNOWNHOSTS s => pure (← Extern.curl_easy_setopt_string curl (sp + 183) s)

/-- Perform a network transfer -/
def curl_easy_perform (h : Handle) : IO Unit := Extern.curl_easy_perform h 
