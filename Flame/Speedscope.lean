import Flame.FlameData

namespace Flame

partial def Node.collapsedStackStrings (node : Node) : List String :=
  go (preprocess node)
where
  go (node : Node) (trace : List String := [])  : List String :=
    match node with
    | .mk name microseconds children =>
      let newTrace := trace ++ [name]
      s!"{String.intercalate ";" newTrace} {microseconds}" :: (children.bind (go · newTrace))

  preprocess (node : Node) : Node :=
    let myTotalTime := node.getTime
    let childrenTotalTime := node.getChildren.foldl (init := 0) (fun acc n => acc + n.getTime)
    let ownTime := myTotalTime - childrenTotalTime
    if ownTime > myTotalTime then
      node.withTime 1 |>.withChildren (node.getChildren.map preprocess)
    else
      node.withTime ownTime |>.withChildren (node.getChildren.map preprocess)

def output (node : Node) : String :=
  let strings := node.getChildren.bind (Node.collapsedStackStrings)
  String.intercalate "\n" strings

end Flame
