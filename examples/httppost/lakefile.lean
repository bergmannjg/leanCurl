import Lake
open System Lake DSL

package httppost

require Curl from "../../"

lean_lib HttpPost

@[default_target]
lean_exe httppost {
  root := `HttpPost
  moreLinkArgs := #[if System.Platform.isWindows then "C:\\Program Files\\Curl\\bin\\libcurl-x64.dll" else "/usr/lib/libcurl.so.4"]
}
