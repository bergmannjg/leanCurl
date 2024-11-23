import Lake
open System Lake DSL

package httppost

def libCurl := match get_config? libCurl with | some v => v | _ => "-lcurl"

require Curl from "../../"

@[default_target]
lean_exe httppost {
  root := `HttpPost
  moreLinkArgs := #[libCurl]
}
