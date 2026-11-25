# 技术调查报告：Lean 证明链溯源方法（anyGeometry 案例）

> 归档日期：2026-11-25 · 分类：方法/经验 · 关联读解：`01-readings/读解_anyGeometry依赖路径与信任链条.md`、`01-readings/读解_外部佐证_Nielsen消融实验与无效性论证.md`

## 1. 调查问题

对上游 RH 证明（Levent Alpöge × Claude，Lean 形式化，175,187 模块）回答一个开放问题（Frank Chu 提出）：

> Main 的证明链到底走不走 `anyGeometry`？它是不是把「真实几何」偷换成了恒真谓词？

## 2. 方法与结果：五层递进

| 层 | 判据 | 结果 | 是否定论 |
| :-- | :-- | :-- | :-- |
| 1 文本定位 | grep 定义 + 出现次数 | 24 文件、162 次文本出现 | ✗ 只证明「被引用」 |
| 2 import 闭包 | Main 闭包 ∩ 目标文件 | 24/24 全在闭包内 | ✗ 闭包覆盖 175,186/175,187，判据平凡 |
| 3 常量全闭包 | 元编程递归展开 `.const` | OOM（RSS ~118GB） | ✗ 传递闭包过大 |
| 4 轻量判据 | 直接常量 + 一层展开 | 前两层不含 anyGeometry | ✗ 只能定性「更深层」 |
| 5 源码级追踪 | 沿 `:=` 逐级展开 | **确认在证明链上** | ✓ |

第 5 层还原出的完整链：

```
riemannHypothesis (Main.lean:4) := rhOfAll
rhOfAll := Formalism.VW.rh_of_every allChi
rh_of_every (CritLine.lean:29) — 应用到平凡特征 N=1 的薄壳
allChi := everyCharacter → every_character_of_literature_of_vWin
  └─ topCovolSlim2_use_alt_alt → … *_alt / *_alt_alt 引理（结论含 geoCl anyGeometry）
anyGeometry (OverIx.lean:19) := fun _ _ _ => True
```

## 3. 关键陷阱（每个都是实测踩过的坑）

1. **「文本出现」≠「在证明链上」**——grep 命中只是起点。
2. **「文件在 import 闭包内」≠「证明依赖它」**——方向 `Closure(Main) ⊇ Consts(proof)` 单向；本项目闭包几乎覆盖全部模块，「在闭包内」几乎恒真，判据失效。
3. **全量元编程 BFS 会 OOM**——RH 证明链传递闭包大到 `#eval` 吃掉 118GB。必须放弃全量，转受控分层。
4. **分层是可行折中**——直接常量 → 一层 → 源码级沿 `:=` 展开，第 5 层不依赖元编程、可控且确定。

## 4. 语义定性（定义是否名副其实）

溯源确认「在链上」只是第一步；真正的问题是「恒真是否偷懒」。关键发现：

- **lam（谱侧）与几何（算术侧）正交**：`oAt_geoOf` 把真实几何 `IsGeoOf` 作为 `Lam3` 之外的独立假设——lam 不自动蕴含几何。
- 证明链全程用 `oAt_any`（lam + 免费恒真几何），**从未兑现 `IsGeoOf`**。
- 泄漏追踪两条精确结论：
  - **语法上不污染**：anyGeometry 被「消化」在成员链内部，最终 `EveryCharacter` 命题干净，不依赖 Γ。
  - **语义上仍是实质缺口**：几何成分全程恒真，真实几何桥接缺失。

## 5. 外部佐证如何收口「悬置判断」

本报告内部结论停在「(A) 无害抽象 vs (B) 偷懒缺口，需数学专家裁决」。Nielsen 两个可复现 Lean 实验把它推进成 (B) 倾向：

- **ablation**：删 `anyGeometry` + `OAt.geo` 字段 → 5,691 模块仍编译、3 公理不变 → 字段是**语义死参数**（可整体删除），排除「正确抽象」。
- **production-geometry**：真填几何 → 高度估计**失效** → 几何环节实质为空/错误。

这印证了本报告方法论里最关键的一层区分：

> **「文本/定义层依赖」（第 5 层结论「在链上」）与「语义层必要性」（Nielsen 的「可删除」）是两个不同问题，可以同时为真。**

## 6. 结论

> 回答「证明依赖某定义吗」，文本 grep 和 import 闭包都不可信，必须下沉到「常量依赖 / 源码级展开」；回答「该定义是否名副其实」，内核永远查不到，只能靠「定义是否被兑现」的语义审计 + 外部可复现实验（消融/替换）来收口。

内核只保证「类型对 + 3 公理」，查不到 anyGeometry 恒真、IsGeoOf 从不进链这类「名不副实」——这正是本项目「定义层验证」的立足点。

## 7. 复用入口

- 方法过程已整理为技能 `.trae/skills/lean-proof-tracing/SKILL.md`。
- 溯源脚本在 `verification/04-scripts/`（`AuditAnyGeometry.lean` / `AuditAnyGeometryLayered.lean` / `AuditAnyGeometryLite.lean`）。
