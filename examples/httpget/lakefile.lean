import Lake
open System Lake DSL Lean

package httpget

def libCurl := match get_config? libCurl with | some v => v | _ => "-lcurl"

def buildType := match get_config? buildType with | some "debug" => Lake.BuildType.debug | _ => Lake.BuildType.release

require Curl from "../../" with NameMap.empty |>.insert (Name.mkSimple "buildType") (if buildType = .debug then "debug" else "release")

@[default_target]
lean_exe httpget {
  buildType := buildType
  root := `HttpGet
  moreLinkArgs := #[libCurl]
}
