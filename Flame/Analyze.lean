import Flame.FlameData
import Lean.Data.Json.Parser

namespace Flame

-- TODO: Maybe add a StateT later
abbrev TCParseT (m : Type → Type) (α : Type) := ExceptT String m α
abbrev TCParseM := TCParseT Id

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
  | n + 1 => upN! pos.up! n

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

def downN! (pos : Position) (n : Nat) : Position :=
  match n with
  | 0 => pos
  | n + 1 => downN! pos.down! n


partial def root! (pos : Position) : Node :=
  match pos with
  | .mk curr [] [] [] => curr
  | _ => root! pos.up!

def addChild (pos : Position) (n : Node) : Position :=
  { pos with current := pos.current.addChild n }

end Position

structure Line where
  targetLevel : Nat
  microseconds : UInt64
  text : String
  deriving Repr

open Lean Parsec in
partial def Node.ofTrace : TCParseT IO Node := do
  let pos ← go ⟨⟨"root", 0, []⟩, [], [], []⟩ 0
  return pos.root!.postprocess
where
  parseLine : Parsec Line := do
    let leadingWhitespaces ← manyChars (pchar ' ')
    skipChar '['
    let _traceClass ← many1Chars (satisfy (']' != ·))
    skipString "] ["
    let seconds ← Json.Parser.num
    let microseconds := seconds.shiftl 6 |>.toFloat.toUInt64
    skipString "s] "
    let text ← manyChars anyChar
    let targetLevel := leadingWhitespaces.length / 2
    return { targetLevel, microseconds, text }

  nextLine : IO (Option Line) := do
    let stdin ← IO.getStdin
    let mut line := (← stdin.getLine) |>.trimRight
    while line != "" do
      match parseLine |>.run line with
      | .ok res => return some res
      | .error _ => line := (← stdin.getLine) |>.trimRight
    return none

  go (pos : Position) (level : Nat) : TCParseT IO Position := do
    let currentLine ← nextLine
    match currentLine with
    | none => return pos
    | some line =>
      let newNode := ⟨line.text, line.microseconds, []⟩
      if line.targetLevel == level then
        go (pos.addChild newNode) level
      else if line.targetLevel > level then
        let stepSize := line.targetLevel - level
        let pos := pos.downN! stepSize |>.addChild newNode
        go pos line.targetLevel
      else
        let stepSize := level - line.targetLevel
        let pos := pos.upN! stepSize |>.addChild newNode
        go pos line.targetLevel

end Flame
