# 读解 · 公理审计：五定理 #print axioms

> 阶段 2 ① 公理审计 · 实测结果 · 2026-11-25

## 结果

在 IP47（全量编译完成后）对五条主定理逐条执行 `#print axioms`，结果一致：

| 定理 | 依赖公理 |
| :-- | :-- |
| `riemannHypothesis` | `propext, Classical.choice, Quot.sound` |
| `riemannZeta_eq_zero_re` | `propext, Classical.choice, Quot.sound` |
| `LFunction_ne_zero_of_half_lt_re` | `propext, Classical.choice, Quot.sound` |
| `LFunction_eq_zero_re` | `propext, Classical.choice, Quot.sound` |
| `LFunction_eq_zero_re_of_isPrimitive` | `propext, Classical.choice, Quot.sound` |

## 结论

**方案 2 成立**：五定理均零额外 axiom、零 sorry，仅依赖 Lean/Mathlib 三条标准公理——`propext`（命题外延）、`Classical.choice`（选择公理）、`Quot.sound`（商类型健全性，为 Lean 内核的一部分）。

这是验证链上最硬的一块证据：**证明未偷用任何非常规公理**。

## 依据

- 编译终态：`done_level=202 built=169260/169260 elapsed=221545s`，0 error。
- 工具链：Lean 4.33.1（commit `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`），mathlib rev `0df444a360eaa60ab8c11dca51a86af692955474`。
- 运行方式：`lake env lean --tstack=400000 diag_axioms.lean`（IP47 项目目录，加载已编译 olean）。
