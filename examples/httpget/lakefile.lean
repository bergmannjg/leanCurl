import Lake
open System Lake DSL

package httpget

def buildType := match get_config? buildType with | some "debug" => Lake.BuildType.debug | _ => Lake.BuildType.release

require Curl from "../../" with NameMap.empty |>.insert "buildType" (if buildType = .debug then "debug" else "release")

lean_lib HttpGet

@[default_target]
lean_exe httpget {
  buildType := buildType
  root := `HttpGet
}
