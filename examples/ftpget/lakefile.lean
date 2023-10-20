import Lake
open System Lake DSL

package ftpget

require Curl from "../../"

lean_lib FtpGet

@[default_target]
lean_exe ftpget {
  root := `FtpGet
}
