import Lean
import Main

open Lean Meta

/-- 递归收集表达式（含展开 def/theorem/opaque 定义）中出现的所有常量名 -/
partial def collectAllConsts (e : Expr) (seen : NameSet) : MetaM NameSet := do
  match e with
  | .const n _ =>
      if seen.contains n then
        return seen
      else
        let seen := seen.insert n
        match (← getEnv).find? n with
        | some (ConstantInfo.defnInfo d)   => collectAllConsts d.value seen
        | some (ConstantInfo.thmInfo t)    => collectAllConsts t.value seen
        | some (ConstantInfo.opaqueInfo o) => collectAllConsts o.value seen
        | _ => return seen
  | .app f a => collectAllConsts a (← collectAllConsts f seen)
  | .lam _ _ b _ => collectAllConsts b seen
  | .forallE _ _ b _ => collectAllConsts b seen
  | .letE _ _ v b _ => collectAllConsts b (← collectAllConsts v seen)
  | .mdata _ e => collectAllConsts e seen
  | .proj _ _ e => collectAllConsts e seen
  | _ => return seen

#eval! show MetaM Unit from do
  let ci ← getConstInfo `riemannHypothesis
  let kind := match ci with
    | .defnInfo _ => "defnInfo"
    | .thmInfo _ => "thmInfo"
    | .opaqueInfo _ => "opaqueInfo"
    | .axiomInfo _ => "axiomInfo"
    | .quotInfo _ => "quotInfo"
    | .inductInfo _ => "inductInfo"
    | .ctorInfo _ => "ctorInfo"
    | .recInfo _ => "recInfo"
  IO.println s!"riemannHypothesis 构造子: {kind}"
  let value ← match ci with
    | .defnInfo v   => pure v.value
    | .thmInfo v    => pure v.value
    | .opaqueInfo v => pure v.value
    | _ => throwError "riemannHypothesis 无证明项，无法做常量依赖判据"
  IO.println "已取得证明项，开始递归收集常量..."
  let consts ← collectAllConsts value ∅
  let constsList := consts.toList
  IO.println s!"证明项 riemannHypothesis 依赖常量总数: {constsList.length}"
  let anys := constsList.filter (fun n => n.toString.contains "anyGeometry")
  IO.println s!"其中含 'anyGeometry' 的常量数: {anys.length}"
  for n in anys do
    IO.println s!"  -> {n}"
