import Lake
open System Lake DSL

package test

require Curl from "../"

lean_lib Test

@[default_target]
lean_exe test {
  root := `Test
}
