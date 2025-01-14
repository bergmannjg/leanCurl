import Curl.Options
import Curl.Extern
import Curl.CurlM

open Lean

/-! Curl Multi interface -/

namespace Curl

private def toInitMError (act : EIO UInt32 α) : EIO Curl.Error α :=
  fun s => match act s with
  | EStateM.Result.error e s => EStateM.Result.error (Curl.Error.initM e) s
  | EStateM.Result.ok v s => EStateM.Result.ok v s

private def toPerformMError (act : EIO UInt32 α) : EIO Curl.Error α :=
  fun s => match act s with
  | EStateM.Result.error e s => EStateM.Result.error (Curl.Error.performM e) s
  | EStateM.Result.ok v s => EStateM.Result.ok v s

/-- Create a multi handle. -/
def curl_multi_init : CurlIO HandleM :=
  toInitMError Extern.curl_multi_init

/-- Add an easy handle to a multi session. -/
def curl_multi_add_handle (curlm: Curl.HandleM) (curl: Curl.Handle) : CurlIO Unit :=
  toInitMError (Extern.curl_multi_add_handle curlm curl)

/-- Remove an easy handle from a multi session . -/
def curl_multi_remove_handle (curlm: Curl.HandleM) (curl: Curl.Handle) : CurlIO Unit :=
  toInitMError (Extern.curl_multi_remove_handle curlm curl)

/-- Reads/writes available data from each easy handle. -/
def curl_multi_perform (curlm: Curl.HandleM) : CurlIO Int :=
  toPerformMError (Extern.curl_multi_perform curlm)

/-- Polls on all easy handles in a multi handle, `timeout` in msecs. -/
def curl_multi_poll (curlm: Curl.HandleM) (timeout : Int) : CurlIO Unit :=
  toPerformMError (Extern.curl_multi_poll curlm timeout)

/-- Read multi stack information. -/
def curl_multi_info_read (curlm: Curl.HandleM) : CurlIO $ Array CurlMsg :=
  toPerformMError (Extern.curl_multi_info_read curlm)
