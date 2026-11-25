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
  let direct := (collectDirectConsts value #[]).toList
  IO.println s!"直接常量: {direct}"
  -- 一层展开：对每个直接常量，若为 def/thm/opaque，取其 value 再 collect
  let mut lvl2 : Array Name := #[]
  for n in direct do
    match (← getEnv).find? n with
    | some (ConstantInfo.defnInfo v) => lvl2 := lvl2 ++ (collectDirectConsts v.value #[])
    | some (ConstantInfo.thmInfo v) => lvl2 := lvl2 ++ (collectDirectConsts v.value #[])
    | some (ConstantInfo.opaqueInfo v) => lvl2 := lvl2 ++ (collectDirectConsts v.value #[])
    | _ => pure ()
  IO.println s!"一层展开后常量数(含重复): {lvl2.size}"
  let lvl2Any := lvl2.filter (fun n => nameHas "anyGeometry" n)
  IO.println s!"一层展开中含 'anyGeometry': {lvl2Any.size}"
  for n in lvl2Any do
    IO.println s!"  -> {n}"
  IO.println "DONE"
