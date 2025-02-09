import Lake
open System Lake DSL

package httpdelete

def libCurl := match get_config? libCurl with | some v => v | _ => "-lcurl"

require Curl from "../../"

@[default_target]
lean_exe httpdelete {
  root := `HttpDelete
  moreLinkArgs := #[libCurl]
}
