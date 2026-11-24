# 读解 · 语句审计：所证即 RH

> 阶段 2 ② 语句审计 · 实测结果 · 2026-11-25

## 五命题定义展开

```lean
def RiemannHypothesis : Prop :=
  ∀ (s : ℂ), riemannZeta s = 0 → (¬∃ n, s = -2 * (↑n + 1)) → s ≠ 1 → s.re = 1 / 2

def RiemannZetaZerosOnLine : Prop :=
  ∀ (s : ℂ), riemannZeta s = 0 → (¬∃ n, s = -2 * (↑n + 1)) → s ≠ 1 → s.re = 1 / 2
```

**关键：`RiemannHypothesis`（Mathlib）与 `RiemannZetaZerosOnLine`（Statements）逐字一致**——不是「等价」，是「完全相同」。

## 五定理类型核对

| 定理 | 类型 | 性质 |
| :-- | :-- | :-- |
| `riemannHypothesis` | `RiemannHypothesis`（Mathlib） | 经典 RH |
| `riemannZeta_eq_zero_re` | `RiemannZetaZerosOnLine`（Statements） | 与上逐字一致 |
| `LFunction_ne_zero_of_half_lt_re` | `DirichletLNonvanishingRightOfHalf` | GRH·非零侧 |
| `LFunction_eq_zero_re` | `DirichletLZerosOnLine` | GRH·临界带零点 |
| `LFunction_eq_zero_re_of_isPrimitive` | `PrimitiveDirichletLZerosOnLine` | GRH·本原特征 |

## 结论

「所证即 RH」成立。`RiemannHypothesis` 展开为经典黎曼猜想：ζ 的非平凡零点（排除负偶数平凡零点、排除 `s = 1`）实部均为 `1/2`。

双重确认：
1. 定理 1 直接用 Mathlib 官方 `RiemannHypothesis` 作类型——所证即官方 RH。
2. 定理 2 用 Statements 的 `RiemannZetaZerosOnLine`，与 Mathlib 定义逐字相同——两条路径殊途同归。

加上定理 3/4/5 覆盖三个 Dirichlet L 的 GRH 表述，完整对应「经典 RH + Dirichlet L 的 GRH」。

## 依据

运行环境：IP47，Lean 4.33.1；`#print` 展开 `RiemannHypothesis`（Mathlib）、`RiemannZetaZerosOnLine` 等五命题定义，`#check` 核对五定理类型。
