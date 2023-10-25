import Lake
open System Lake DSL

package httpdelete

require Curl from "../../"

lean_lib HttpDelete

@[default_target]
lean_exe httpdelete {
  root := `HttpDelete
  moreLinkArgs := #[if System.Platform.isWindows then "C:\\Program Files\\Curl\\bin\\libcurl-x64.dll" else "/usr/lib/libcurl.so.4"]
}
