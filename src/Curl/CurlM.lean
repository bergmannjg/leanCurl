import Curl.Errors

/-! Foreign functions -/

namespace Curl

abbrev CurlIO : Type → Type := EIO Curl.Error

def toError (e : Curl.Error) : IO.Error := .userError s!"{e}"

instance : MonadLift CurlIO IO := ⟨EIO.toIO toError⟩
