import Lake
open System Lake DSL

package ftpget

require Curl from "../../"

lean_lib FtpGet

@[default_target]
lean_exe ftpget {
  root := `FtpGet
  moreLinkArgs := #[if System.Platform.isWindows then "C:\\Program Files\\Curl\\bin\\libcurl-x64.dll" else "/usr/lib/libcurl.so.4"]
}
