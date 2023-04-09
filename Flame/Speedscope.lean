import Flame.FlameData

namespace Flame

partial def Node.collapsedStackStrings (node : Node) (trace : List String := []) : List String :=
  match node with
  | .mk name seconds children =>
    let microseconds := seconds.shiftl 6 |>.toFloat.toUInt64
    let newTrace := trace ++ [name]
    s!"{String.intercalate ";" newTrace} {microseconds}" :: (children.bind (Node.collapsedStackStrings · newTrace))

def output (node : Node) : String :=
  let strings := node.getChildren.bind (Node.collapsedStackStrings)
  String.intercalate "\n" strings

end Flame
