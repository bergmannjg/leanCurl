import Lake
open System Lake DSL

package httppost

require Curl from "../../"

lean_lib HttpPost

@[default_target]
lean_exe httppost {
  root := `HttpPost
}
