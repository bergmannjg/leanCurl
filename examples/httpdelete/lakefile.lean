import Lake
open System Lake DSL

package httpdelete

require Curl from "../../"

lean_lib HttpDelete

@[default_target]
lean_exe httpdelete {
  root := `HttpDelete
}
