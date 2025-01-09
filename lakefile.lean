import Lake
open Lake DSL

/-
  example of require statement for packages using Curl

  require Curl from "..." with NameMap.empty |>.insert (Name.mkSimple "libcurlSharedLib") "/usr/lib/libcurl.so.4"
-/

-- try find path to libcurl of curl executable
def libPathOfCurlExec? : IO $ Option String := do
  let p ← IO.Process.run { cmd := "/bin/sh", args := #["-c", "ldd $(which curl) | grep libcurl | awk '{ print $3 }'"]}
  pure (if p.trim.isEmpty then none else some p.trim)

def libcurlPath : String :=
  match run_io (libPathOfCurlExec?) with | some p => p | none => "-lcurl"

/- on macOS the shared library libcurl.dylib is in a shared cache file,
   after reinstalling curl a copy of libcurl.dylib is in directory /opt/homebrew/opt/curl/lib -/
def pathToLibCurl? : IO $ Option String := do
  let path :=  "/opt/homebrew/opt/curl/lib/libcurl.dylib" -- needs brew reinstall curl
  if ← System.FilePath.pathExists path then pure path else pure none

def libcurlPathOSX : String :=
  match run_io (pathToLibCurl?) with | some path => path | none => "-lcurl"

def libcurlVersion := match get_config? libcurlVersion with | some v => v | none => "7.68.0"
def libcurlSharedLib := match get_config? libcurlSharedLib with
                        | some v => v
                        | none =>
                            if System.Platform.isWindows
                            then "C:\\Program Files\\Curl\\bin\\libcurl-x64.dll"
                            else if System.Platform.isOSX
                            then libcurlPathOSX
                            else libcurlPath

def libcurlIncludeDir := match get_config? libcurlIncludeDir with | some v => v | none => "native/curl-" ++ libcurlVersion

def buildType := match get_config? buildType with | some "debug" => Lake.BuildType.debug | _ => Lake.BuildType.release

package Curl {
}

@[default_target] lean_lib Curl  {
  buildType := buildType
  srcDir := "src"
}

@[test_driver]
lean_exe test {
  srcDir := "test"
  buildType := buildType
  root := `Test
  moreLinkArgs := #[libcurlSharedLib]
}

target leancurl.o pkg : System.FilePath := do
  let dirPrefix := if System.FilePath.isAbsolute libcurlIncludeDir then "" else (pkg.srcDir.toString ++ "/")
  let defines := if buildType = .debug then #["-DDEBUG"] else #[]
  let oFile := pkg.buildDir / "native/" / "leancurl.o"
  let srcJob ← inputTextFile  <| pkg.dir / "native/" / "leancurl.cpp"
  let flags := #["-I", (← getLeanIncludeDir).toString, "-I", dirPrefix ++ libcurlIncludeDir] ++ defines
  buildO oFile srcJob flags #["-fPIC"]

extern_lib libleancurl pkg := do
  let name := nameToStaticLib "leancurl"
  let leancurl ← leancurl.o.fetch
  buildStaticLib (pkg.nativeLibDir / name) #[leancurl]

-- print libcurlSharedLib
post_update do
  IO.println s!"path to libcurl: {libcurlSharedLib}"
  IO.println s!"please add path to 'moreLinkArgs' option"
