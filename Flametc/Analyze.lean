import Flametc.FlameData
import Lean.Data.Json.Parser

namespace Flametc

-- TODO: Maybe add a StateT later
abbrev TCParseT (m : Type → Type) (α : Type) := ExceptT String m α
abbrev TCParseM := TCParseT Id

def prefixAtLevel (level : Nat) : String :=
  go level "" ++ "[Meta.synthInstance"
where
  go (level : Nat) (acc : String) : String :=
    match level with
    | 0 => acc
    | n + 1 => go n (acc ++ "  ")

instance : Add Lean.JsonNumber where
  add lhs rhs :=
    let (bigger, smaller) := if lhs.exponent < rhs.exponent then (lhs, rhs) else (rhs, lhs)
    let factor := 10^(smaller.exponent - bigger.exponent)
    let adjustedRhs := bigger.mantissa * factor
    let finalMantissa := adjustedRhs + smaller.mantissa
    { mantissa := finalMantissa, exponent := smaller.exponent}

partial def Node.ofTrace (trace : String) : TCParseM Node := do
  let lines := trace.splitOn "\n"
  let (_, root) ← go lines ⟨"root", 0, []⟩ 0
  let time := root.getChildren.foldl (init := 0) (· + ·.getTime)
  -- TODO: add total amount to this node
  return root.withTime time
where
  parseLine (trace : String) : TCParseM (Lean.JsonNumber × String) := do
    -- TODO: optimizable with level
    let trace := Substring.mk trace (trace.find (']' == ·)) trace.endPos |>.toString
    let startOfTime := trace.find ('[' == ·) + ⟨1⟩
    let endOfTime := trace.find ('s' == ·)
    let timeStr := Substring.mk trace startOfTime (endOfTime) |>.toString
    let .ok time := Lean.Json.Parser.num |>.run timeStr | throw "Invalid number"
    let startOfName := endOfTime + ⟨3⟩
    let name := Substring.mk trace startOfName trace.endPos |>.toString
    return (time, name)

  go (lines : List String) (current : Node) (level : Nat) : TCParseM (List String × Node) := do
    match lines with
    | [] => return ([], current)
    | line :: rest =>
      let pref := prefixAtLevel level
      -- TODO perf is optimiztable by using level + 1 and slicing
      -- We are still at the current level
      if line.startsWith pref then
        -- since i am too lazy to parse all lines properly we just ask for forgiveness
        -- for lines with no time attached
        if let .ok (time, name) := parseLine line then
          let newNode := ⟨name, time, []⟩
          go rest (current.addChild newNode) level
        else
          go rest current level
      -- We are one level deeper now
      else if line.startsWith ("  " ++ pref) then
        let (nextNode :: otherNodes) := current.getChildren | throw "should be unreachable"
        let (rest, finalNextNode) ← go lines nextNode (level + 1)
        let current := current.withChildren (finalNextNode :: otherNodes) 
        go rest current level
      -- We are at a higher level now 
      else if level > 0 && line.trimLeft.startsWith (prefixAtLevel 0) then
        return (lines, current)
      else
        -- Some irrelevant line to the trace, continue
        go rest current level

end Flametc
