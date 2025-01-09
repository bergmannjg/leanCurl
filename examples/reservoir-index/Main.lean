import Curl
import Lean.Data.Json.Parser
import Lean.Data.Json.FromToJson
import Lean.Data.HashMap

open Lean
open Curl

/-
  load file https://github.com/leanprover/reservoir-index/archive/refs/heads/master.zip
  and load toolchain data of indexed repositories
-/

open IO.Process

structure Source where
  repoUrl : String
  defaultBranch : Option String
deriving FromJson

structure MetaData where
  sources : Array Source
deriving FromJson

def toMetaData (s : String) : Except String MetaData := do
  Json.parse s >>= fromJson?

def loadToolchain (curl : Handle) (project : String) (branch : String) : IO $ Option String := do
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}
    let h ← IO.mkRef { : IO.FS.Stream.Buffer}

    let url := "https://raw.githubusercontent.com/" ++ project ++ "/" ++ branch ++ "/lean-toolchain"
    curl_set_option curl (CurlOption.URL url)
    curl_set_option curl (CurlOption.VERBOSE 0)
    curl_set_option curl (CurlOption.FOLLOWLOCATION 1)
    curl_set_option curl (CurlOption.WRITEDATA response)
    curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
    curl_set_option curl (CurlOption.HEADERDATA h)
    curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)
    curl_easy_perform curl

    IO.println s!"loaded {url}"

    let headers := String.fromUTF8! (← h.get).data
    if List.any (Curl.getHeaderData headers) (·.status = 200)
    then
      let bytes ← response.get
      pure (String.fromUTF8! bytes.data)
    else pure none

def loadToolchains (curl : Handle) (archive : System.FilePath) : IO $ Array String := do
  let metaData ←
    (← System.FilePath.walkDir archive)
    |> Array.filter (fun (file : System.FilePath) => file.toString.endsWith "metadata.json")
    |> Array.mapM (fun (file : System.FilePath) => do
      let content ← IO.FS.readFile file
      IO.ofExcept (toMetaData content))

  let result ←
    metaData
    |> Array.mapM (fun (m : MetaData) => do
        if h : 0 < m.sources.size then
          let source := m.sources.get 0 h
          let project := source.repoUrl.drop "https://github.com/".length
          match source.defaultBranch with
          | some defaultBranch => pure (some (← loadToolchain curl project defaultBranch))
          | _ => pure none
        else pure none)

  result
  |> Array.filterMap (fun r => match r with | some r => r | none => none)
  |> pure

def loadArchive (curl : Handle) : IO System.FilePath := do
    let response ← IO.mkRef { : IO.FS.Stream.Buffer}
    let h ← IO.mkRef { : IO.FS.Stream.Buffer}

    curl_set_option curl (CurlOption.URL "https://github.com/leanprover/reservoir-index/archive/refs/heads/master.zip")
    curl_set_option curl (CurlOption.VERBOSE 0)
    curl_set_option curl (CurlOption.FOLLOWLOCATION 1)
    curl_set_option curl (CurlOption.WRITEDATA response)
    curl_set_option curl (CurlOption.WRITEFUNCTION Curl.writeBytes)
    curl_set_option curl (CurlOption.HEADERDATA h)
    curl_set_option curl (CurlOption.HEADERFUNCTION Curl.writeBytes)
    curl_easy_perform curl

    let headers := String.fromUTF8! (← h.get).data
    if List.any (Curl.getHeaderData headers) (·.status = 200)
    then
      let bytes ← response.get
      IO.FS.writeBinFile ".lake/reservoir-index.zip" bytes.data

      let output ←  output { cmd := "/usr/bin/unzip", args := #["-oq", "reservoir-index.zip"], cwd := ".lake/" }
      if output.exitCode = 0
      then pure ".lake/reservoir-index-master"
      else throw (IO.userError output.stderr)
    else throw (IO.userError s!"url not found")

def main : IO Unit := do
  try
    let curl ← curl_easy_init
    let archive ← loadArchive curl
    let toolchains ← loadToolchains curl archive
    toolchains
    |> Array.groupByKey (fun t => t.trim)
    |> Std.HashMap.toArray
    |> Array.map (fun (k, v) => (k, v.size))
    |> (fun arr => Array.qsort arr (lt := fun (a, _) (b, _) => a < b))
    |> Array.forM (fun (k, v) => IO.println s!"toolchain count: {k} {v}")
  catch e => IO.println s!"error: {e}"
