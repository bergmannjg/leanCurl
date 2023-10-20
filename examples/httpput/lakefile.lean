import Lake
open System Lake DSL

package httpput

def buildType := match get_config? buildType with | some "debug" => Lake.BuildType.debug | _ => Lake.BuildType.release

require Curl from "../../" with NameMap.empty |>.insert "buildType" (if buildType = .debug then "debug" else "release")

lean_lib HttpPut

@[default_target]
lean_exe httpput {
  buildType := buildType
  root := `HttpPut
}
