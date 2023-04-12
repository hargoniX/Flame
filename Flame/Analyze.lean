import Flame.FlameData
import Lean.Data.Json.Parser

namespace Flame

-- TODO: Maybe add a StateT later
abbrev TCParseT (m : Type → Type) (α : Type) := ExceptT String m α
abbrev TCParseM := TCParseT Id

def prefixAtLevel (level : Nat) : String :=
  go level "" ++ "["
where
  go (level : Nat) (acc : String) : String :=
    match level with
    | 0 => acc
    | n + 1 => go n (acc ++ "  ")

structure Position where
  current : Node
  before : List Node
  after : List Node
  path : List (List Node × Node × List Node)
deriving Inhabited, Repr

namespace Position

def up! (pos : Position) : Position :=
  match pos.path with
  | ((before, parent, after) :: path) =>
    {
      current := parent.withChildren (pos.before ++ [pos.current] ++ pos.after) 
      before := before
      after := after
      path := path
    }
  | _ => panic! "Cannot go further up"

def upN! (pos : Position) (n : Nat) : Position :=
  match n with
  | 0 => pos
  | n + 1 => upN! (pos.up!) n

def down! (pos : Position) : Position :=
  match pos.current.getChildren with
  | [] => panic! "Cannot go further downn"
  | c :: cs =>
    {
      current := c
      before := []
      after := cs
      path := (pos.before, pos.current, pos.after) :: pos.path
    }

partial def root! (pos : Position) : Node :=
  match pos with
  | .mk curr [] [] [] => curr
  | _ => root! pos.up!

def addChild (pos : Position) (n : Node) : Position :=
  { pos with current := pos.current.addChild n }

end Position 

 

partial def Node.ofTrace : TCParseT IO Node := do
  let pos ← go (← nextLine) ⟨⟨"root", 0, []⟩, [], [], []⟩ 0
  return pos.root!
where
  parseLine (trace : String) : TCParseM (Lean.JsonNumber × String) := do
    let trace := Substring.mk trace (trace.find (']' == ·)) trace.endPos |>.toString
    let startOfTime := trace.find ('[' == ·) + ⟨1⟩
    let endOfTime := trace.find ('s' == ·)
    let timeStr := Substring.mk trace startOfTime (endOfTime) |>.toString
    let .ok time := Lean.Json.Parser.num |>.run timeStr | throw "Invalid number"
    let startOfName := endOfTime + ⟨3⟩
    let name := Substring.mk trace startOfName trace.endPos |>.toString
    return (time, name)

  nextLine : IO String := do
    let line ← (← IO.getStdin).getLine
    return line.trimRight

  go (currentLine : String) (pos : Position) (level : Nat) : TCParseT IO Position := do
    match currentLine with
    | "" => return pos
    | line =>
      let pref := prefixAtLevel level
      if line.startsWith pref then
        -- since i am too lazy to parse all lines properly we just ask for forgiveness
        -- for lines with no time attached
        if let .ok (seconds, name) := parseLine line then
          let microseconds := seconds.shiftl 6 |>.toFloat.toUInt64
          let newNode := ⟨name, microseconds, []⟩
          go (← nextLine) (pos.addChild newNode) level
        else
          go (← nextLine) pos level
      else if line.startsWith ("  " ++ pref) then
        -- We are one level deeper now
        go currentLine pos.down! (level + 1)
      else if level > 0 && line.trimLeft.startsWith (prefixAtLevel 0) then
        -- very hacky way to get amount of leading whitespacesf
        let leadingWhitespaces := line.length - line.trimLeft.length
        let stepSize := (level * 2 - leadingWhitespaces) / 2
        let pos := pos.upN! stepSize
        go line pos (level - stepSize)
      else
        -- Some irrelevant line to the trace, continue
        go (← nextLine) pos level
      
end Flame
