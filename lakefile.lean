import Lake
open Lake DSL

/-
  example of require statement for packages using Curl

  require Curl from "..." with NameMap.empty |>.insert "libcurlSharedLib" "/usr/lib/libcurl.so.4"
-/

def libcurlVersion := match get_config? libcurlVersion with | some v => v | none => "7.68.0"
def libcurlSharedLib := match get_config? libcurlSharedLib with
                        | some v => v
                        | none =>
                            if System.Platform.isWindows
                            then "C:\\Program Files\\Curl\\bin\\libcurl-x64.dll"
                            else "-lcurl"
def libcurlIncludeDir := match get_config? libcurlIncludeDir with | some v => v | none => "native/curl-" ++ libcurlVersion

def buildType := match get_config? buildType with | some "debug" => Lake.BuildType.debug | _ => Lake.BuildType.release

package Curl {
  moreLinkArgs := #[libcurlSharedLib]
}

@[default_target] lean_lib Curl  {
  buildType := buildType
  srcDir := "src"
}

@[default_target]
lean_exe test {
  srcDir := "test"
  buildType := buildType
  root := `Test
}

target leancurl.o pkg : FilePath := do
  let dirPrefix := if System.FilePath.isAbsolute libcurlIncludeDir then "" else (pkg.srcDir.toString ++ "/")
  let defines := if buildType = .debug then #["-DDEBUG"] else #[]
  let oFile := pkg.buildDir / "native/" / "leancurl.o"
  let srcJob ← inputFile <| pkg.dir / "native/" / "leancurl.cpp"
  let flags := #["-I", (← getLeanIncludeDir).toString, "-I", dirPrefix ++ libcurlIncludeDir, "-fPIC"] ++ defines
  buildO "leancurl.cpp" oFile srcJob flags

extern_lib libleancurl pkg := do
  let name := nameToStaticLib "leancurl"
  let leancurl ← fetch <| pkg.target ``leancurl.o
  buildStaticLib (pkg.nativeLibDir / name) #[leancurl]
