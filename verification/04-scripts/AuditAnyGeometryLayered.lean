import Lean
import Main

open Lean Meta

partial def collectDirectConsts (e : Expr) (acc : Array Name) : Array Name :=
  match e with
  | .const n _ => acc.push n
  | .app f a => collectDirectConsts a (collectDirectConsts f acc)
  | .lam _ _ b _ => collectDirectConsts b acc
  | .forallE _ _ b _ => collectDirectConsts b acc
  | .letE _ _ v b _ => collectDirectConsts b (collectDirectConsts v acc)
  | .mdata _ e => collectDirectConsts e acc
  | .proj _ _ e => collectDirectConsts e acc
  | _ => acc

def nameHas (sub : String) (n : Name) : Bool :=
  n.toString.contains sub

#eval! show MetaM Unit from do
  let ci ← getConstInfo `riemannHypothesis
  let value ← match ci with
    | .thmInfo v => pure v.value
    | .defnInfo v => pure v.value
    | _ => throwError "riemannHypothesis 无证明项"
  let mut frontier : List Name := (collectDirectConsts value #[]).toList
  let mut visited : NameSet := {}
  let mut visitedCount := 0
  let mut depth := 0
  let mut hitAny : Array Name := #[]
  while !frontier.isEmpty && depth < 30 && visitedCount < 50000 do
    let curAny := frontier.filter (fun n => nameHas "anyGeometry" n)
    let curGeo := frontier.filter (fun n => nameHas "geoCl" n)
    let cur3rd := frontier.filter (fun n => nameHas "ThirdPlaceSeries" n)
    IO.println s!"[层 {depth}] frontier={frontier.length} anyGeometry={curAny.length} geoCl={curGeo.length} ThirdPlaceSeries={cur3rd.length}"
    for n in curAny do
      IO.println s!"    [HIT-anyGeometry] {n}"
      hitAny := hitAny.push n
    let mut nextSet : NameSet := {}
    for n in frontier do
      if visited.contains n then continue
      visited := visited.insert n
      visitedCount := visitedCount + 1
      match (← getEnv).find? n with
      | some (ConstantInfo.defnInfo v) =>
          for m in (collectDirectConsts v.value #[]) do
            if !visited.contains m then nextSet := nextSet.insert m
      | some (ConstantInfo.thmInfo v) =>
          for m in (collectDirectConsts v.value #[]) do
            if !visited.contains m then nextSet := nextSet.insert m
      | some (ConstantInfo.opaqueInfo v) =>
          for m in (collectDirectConsts v.value #[]) do
            if !visited.contains m then nextSet := nextSet.insert m
      | _ => pure ()
    frontier := nextSet.toList
    depth := depth + 1
  IO.println s!"追踪结束：depth={depth} visited={visitedCount} hitAnyGeometry={hitAny.size} frontier剩余={frontier.length}"
  for n in hitAny do
    IO.println s!"  -> {n}"
  IO.println "DONE"
