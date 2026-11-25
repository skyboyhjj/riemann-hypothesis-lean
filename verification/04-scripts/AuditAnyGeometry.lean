import Lean
import Main

open Lean Meta

/-- 收集表达式里直接出现的常量名（不递归展开定义） -/
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

#eval! show MetaM Unit from do
  let ci ← getConstInfo `riemannHypothesis
  let value ← match ci with
    | .thmInfo v => pure v.value
    | .defnInfo v => pure v.value
    | _ => throwError "riemannHypothesis 无证明项"
  IO.println "已取得证明项，开始 BFS 收集传递闭包常量..."
  let mut visited : NameSet := {}
  let mut queue : List Name := (collectDirectConsts value #[]).toList
  let mut iter := 0
  while !queue.isEmpty do
    let n := queue.head!
    queue := queue.tail!
    if visited.contains n then continue
    visited := visited.insert n
    iter := iter + 1
    if iter % 20000 == 0 then
      IO.println s!"  ... 已处理 {iter} 个常量 (队列 {queue.length})"
    match (← getEnv).find? n with
    | some (ConstantInfo.defnInfo v) => queue := (collectDirectConsts v.value #[]).toList ++ queue
    | some (ConstantInfo.thmInfo v) => queue := (collectDirectConsts v.value #[]).toList ++ queue
    | some (ConstantInfo.opaqueInfo v) => queue := (collectDirectConsts v.value #[]).toList ++ queue
    | _ => pure ()
  let constsList := visited.toList
  IO.println s!"证明项 riemannHypothesis 依赖常量总数: {constsList.length}"
  let anys := constsList.filter (fun n => n.toString.contains "anyGeometry")
  IO.println s!"其中含 'anyGeometry' 的常量数: {anys.length}"
  for n in anys do
    IO.println s!"  -> {n}"
