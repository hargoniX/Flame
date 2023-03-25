import Lake
open Lake DSL

package «flametc» {
  -- add package configuration options here
}

lean_lib «Flametc» {
  -- add library configuration options here
}

@[default_target]
lean_exe «flametc» {
  root := `Main
}
