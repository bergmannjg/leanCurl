/-! HeaderData utilities -/

namespace Curl

open Lean

/-- HTTP header data -/
structure HeaderData where
  version : String
  status : Nat
  fields : List (String × String)
deriving Repr

instance : ToString HeaderData where
  toString hd := s!"{hd.version} {hd.status} {hd.fields}"

/-- parse `headerData` from `CurlOption.HEADERDATA`, may contain data from multiple http requests -/
def getHeaderData (headerData : String) : List HeaderData :=
  let splits := headerData.splitOn "\r\n"
  let (hd, arr) :=
  splits.foldl
    (init := ((none, []) : (Option HeaderData) × (List HeaderData)))
    (fun (hd, arr) s =>
      if s.startsWith "HTTP"
      then
        let arr := match hd with | some hd => hd :: arr | none => arr
        match s.splitOn " " with
        | version :: status :: _ =>
          match status.trim.toNat? with
          | some status => (some ⟨version, status, []⟩, arr)
          | _ => (hd, arr)
        | _ => (hd, arr)
      else
        let pos := s.find (· = ':')
        if pos.byteIdx < s.length
        then
          let subs := s.toSubstring
          let name := subs.extract ⟨0⟩ pos
          let value := subs.extract (pos + ':') ⟨s.length⟩
          let field := (name.toString.trim, value.toString.trim)
          match hd with
          | some hd => (some {hd with fields := field :: hd.fields},  arr)
          | none => (hd, arr)
        else (hd, arr))

  match hd with | some hd => hd :: arr | none => arr
