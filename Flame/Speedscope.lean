import Flame.FlameData

namespace Flame

partial def Node.collapsedStackStrings (node : Node) (trace : List String := []) : List String :=
  match node with
  | .mk name seconds children =>
    let microseconds := seconds.shiftl 6 |>.toFloat.toUInt64
    let pref := String.intercalate ";" trace
    let newTrace := trace ++ [name]
    s!"{pref}{name} {microseconds}" :: (children.bind (Node.collapsedStackStrings · newTrace))

def output (node : Node) : String :=
  String.intercalate "\n" node.collapsedStackStrings

end Flame
