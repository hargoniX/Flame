import Lean.Data.Json.FromToJson

namespace Flametc

inductive Node where
| mk (name : String) (value : Lean.JsonNumber) (children : List Node)
deriving Inhabited, Repr

partial def Node.toJson (node : Node) : Lean.Json :=
  match node with
  | .mk name value children =>
    Lean.Json.mkObj [
      ("name", name),
      ("value", Lean.toJson value),
      ("children", Lean.toJson <| children.map Node.toJson)
    ]

instance : Lean.ToJson Node where
  toJson := Node.toJson

def Node.addChild (node child : Node) : Node :=
  match node with
  | .mk name value children => .mk name value (child :: children)

def Node.getChildren (node : Node) : List Node :=
  match node with
  | .mk _ _ children => children

def Node.withChildren (node : Node) (children : List Node) : Node :=
  match node with
  | .mk name value _ => .mk name value children

def Node.getTime (node : Node) : Lean.JsonNumber :=
  match node with
  | .mk _ value _ => value 

def Node.withTime (node : Node) (time : Lean.JsonNumber) : Node :=
  match node with
  | .mk name _ children => .mk name time children 

end Flametc
