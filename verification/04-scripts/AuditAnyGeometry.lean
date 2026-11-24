import Lean
import Main

open Lean Meta

/--
递归收集一个表达式（含展开 def/theorem 定义）中出现的所有常量名。
对 `.const n`：先记下 n，若 n 是 defn/theorem 且未见过，则递归进入其 `.value`。
这样能回答「证明项的常量依赖闭包里有没有 anyGeometry」。
-/
partial def collectAllConsts (e : Expr) (seen : NameSet) : MetaM NameSet := do
  match e with
  | .const n _ =>
      if seen.contains n then
        return seen
      else
        let seen := seen.insert n
        match (← getEnv).find? n with
        | some (ConstantInfo.defnInfo d) => collectAllConsts d.value seen
        | some (ConstantInfo.thmInfo t)  => collectAllConsts t.value seen
        | _ => return seen
  | .app f a => collectAllConsts a (← collectAllConsts f seen)
  | .lam _ _ b _ => collectAllConsts b seen
  | .forallE _ _ b _ => collectAllConsts b seen
  | .letE _ _ v b _ => collectAllConsts b (← collectAllConsts v seen)
  | .mdata _ e => collectAllConsts e seen
  | .proj _ _ e => collectAllConsts e seen
  | _ => return seen

#eval show MetaM Unit from do
  let ci ← getConstInfo `riemannHypothesis
  let consts ← collectAllConsts ci.value ∅
  let constsList := consts.toList
  IO.println s!"证明项 riemannHypothesis 依赖常量总数: {constsList.length}"
  let anys := constsList.filter (fun n => n.toString.contains "anyGeometry")
  IO.println s!"其中含 'anyGeometry' 的常量数: {anys.length}"
  for n in anys do
    IO.println s!"  -> {n}"
