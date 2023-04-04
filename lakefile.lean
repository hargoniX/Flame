import Lake
open Lake DSL

package «flame» {
  -- add package configuration options here
}

lean_lib «Flame» {
  -- add library configuration options here
}

@[default_target]
lean_exe «flame» {
  root := `Main
}
