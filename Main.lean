import Flame

def main (args : List String) : IO Unit := do
  let logfile := args[0]!
  let outfile := args[1]!
  let content ← IO.FS.readFile logfile
  match Flame.Node.ofTrace content with
  | .ok node => IO.FS.writeFile outfile (Flame.output node)
  | .error err => IO.println s!"Error while parsing: {err}"
