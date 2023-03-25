import Flametc

def main (args : List String) : IO Unit := do
  let logfile := args[0]!
  let content ← IO.FS.readFile logfile
  match Flametc.Node.ofTrace content with
  | .ok node => Flametc.output node
  | .error err => IO.println s!"Error while parsing: {err}"
