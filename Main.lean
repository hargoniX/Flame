import Flame

def main : IO Unit := do
  let res ← Flame.Node.ofTrace
  match res with
  | .ok node => IO.println (Flame.output node)
  | .error err => IO.println s!"Error while parsing: {err}"
