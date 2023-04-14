namespace Flame

inductive Node where
| mk (name : String) (value : UInt64) (children : List Node)
deriving Inhabited, Repr

namespace Node

def addChild (node child : Node) : Node :=
  match node with
  | .mk name value children => .mk name value (child :: children)

def getName (node : Node) : String :=
  match node with
  | .mk name _ _ => name

def getChildren (node : Node) : List Node :=
  match node with
  | .mk _ _ children => children

def withChildren (node : Node) (children : List Node) : Node :=
  match node with
  | .mk name value _ => .mk name value children

def getTime (node : Node) : UInt64 :=
  match node with
  | .mk _ value _ => value 

def withTime (node : Node) (time : UInt64) : Node :=
  match node with
  | .mk name _ children => .mk name time children 


partial def toString (node : Node) : String :=
  String.intercalate "\n" (go node 0)
where
  nWhiteSpaces (n : Nat) : String := n.fold (init := "") (fun _ acc => acc ++ " ")
  go (node : Node) (indent : Nat) : List String :=
    match node with
    | mk name value children =>
      s!"{nWhiteSpaces indent}[{value}us] {name}" :: children.bind (go · (indent + 2))

instance : ToString Node where
  toString := toString

partial def postprocess (node : Node) : Node :=
  match node with
  | mk name value children =>
    .mk name value (children.reverse.map postprocess)

end Node
end Flame
