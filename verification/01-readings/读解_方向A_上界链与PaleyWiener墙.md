# 读解：上界链与 Paley–Wiener 墙——同一条临界线的两条路

> 归档日期：2026-11-28 · 对象：lsernau/grh-lean 的 `grh/src/New/UpperBound`（55 文件 / 35,318 行）
> 对应：综述 §8.3 方向 A——「`UpperBound` 的『上界链』与我们的『Paley–Wiener 墙』是否同一件事」
> 材料：`grh/GUIDE.md` + `grh/INDEX.md`（证明自带的结构说明，逐文件头注释）

---

## 一、结论先行

**不是同一件事。** 它们是「同一条临界线 `c = 1/2` 的两条路」：

- **Paley–Wiener 墙**是**解析路线**的障碍（「换核」：找又快又窄的核，灵敏度 `~ 1/c` 与可算性 `c > 1/2` 不可兼得）；
- **UpperBound 上界链**是**代数路线**的工具（「复合 theta lift」的大小上界，由 p-adic 可除性 + Hecke 算子初等因子 + seesaw 恒等式精确算出）。

证明没有走「换核」那条路，所以**绕开了 Paley–Wiener 对偶的不可兼得**——这就是对方向 A 的回答。

---

## 二、Paley–Wiener 墙（线二的回顾）

线二在「正性—谱—符号」族里撞到的墙之一（综述 §3.5）：

| 路线 | 障碍 |
|---|---|
| 换核（找又快又窄的核） | **Paley–Wiener 对偶**：灵敏度 `~ 1/c` 与素数侧可算性 `c > 1/2` 不可兼得 |

即：想让核「快」（在宽解析带内 → 能探到高处的零点）就得让奇性距离 `c` 大；想让核「窄」（素数侧求和收敛、可算）就得让 `c` 小。而 RH 需要的正是**同时**又快又窄（检测 `re s = 1/2` 的零点需要 `c > 1/2`，但 `c > 1/2` 又毁了素数侧的可算性）。这是傅里叶不确定性在解析数论里的化身。

---

## 三、UpperBound 上界链（实测读码）

### 位置与角色

`New/UpperBound` 的职责（GUIDE.md 第 23 行）：

> **Upper bound: a composite lift** — Theta kernels between definite spaces（`Kernels`）；Source forms, target forms and chains of lifts（`Objects`）；The seesaw identity（`Seesaw`）；Divisibility of the composite lift（`Divisibility`）；Size of the composite lift / short source forms（`Size`）；Elementary divisors of a Hecke operator（`ElementaryDivisors`）。

六个子目录即「上界链」的六个环节：

| 子目录 | 环节 |
|---|---|
| `Objects` | 源形式、目标形式、提升链 `Y₀ → Y_m`（`RowChain`、`PoincareMap`） |
| `Kernels` | 定空间之间的 theta 核、jet 的伽罗瓦共轭与 archimedean 界 |
| `Seesaw` | **跷跷板恒等式**——把 theta 积分展开成有限和（`SeesawIdentity` 等 14 文件） |
| `Divisibility` | 复合 lift 在每个素点的可除性（`LocalDivisibility`、`ValuationAtLevel`） |
| `Size` | 复合 lift 的大小、短源形式（`Estimates`、`ShortColumns`、`ClassCount`） |
| `ElementaryDivisors` | Hecke 算子的初等因子（`MarkOperator`、`RootLemma`、`AveragingMap`、`DefectCount`） |

### 机制（GUIDE.md 第 74 行）

链上每个提升方向都被记为「**其上界减去其保证的可除性**」：

> idle direction：each is charged **the upper bound for its size less its guaranteed divisibility**, and `D.heightLe_liftDeterminant_ratio` repays it.

即：上界链 = 逐 lift 累加（size − divisibility），总得到复合 lift 的上界。

### 终点（INDEX.md「The last step」表）

上界链喂给最后一步：

```
one-sided bound x^(−1/2 + ε)  ──►  零自由半平面 re s > 1/2  ──►  grh
   (New/Reduction/OneSidedBound)   (New/Reduction/Zeros/Criterion)   (New/Reduction/OneSidedBound)
```

临界指数 `1/2` 出现在这里，与 Paley–Wiener 墙的 `c = 1/2` 是同一个数。

---

## 四、判定：同一条临界线，两条不同的路

| 维度 | Paley–Wiener 墙 | UpperBound 上界链 |
|---|---|---|
| 所属路线 | 解析（换核） | 代数（theta lift + p-adic） |
| 控制的量 | 核的灵敏度 vs 可算性 | 复合 lift 的大小 |
| 工具 | 傅里叶 / Paley–Wiener 定理 | seesaw 恒等式、p-adic 可除性、Hecke 初等因子 |
| 卡住/成功 | **卡在** `c > 1/2` 不可兼得 | **精确到** `x^(−1/2+ε)` |
| 是否「换核」 | 要换（找又快又窄） | 不换（用标准 theta 核，改控大小） |

**关键区别**：证明没有去找一个「又快又窄」的核（那正是 Paley–Wiener 墙所在），而是**固定标准 theta 核**，把问题从「核的解析性质」转成「theta lift 的代数大小」，再用 seesaw + 可除性 + 初等因子把大小算到 `1/2` 的精度。所以它**绕开**了 Paley–Wiener 对偶，而不是解决了它。

---

## 五、结论分级

| 结论 | 级别 |
|---|---|
| UpperBound 的六子目录、复合 lift 职责、终点 one-sided bound | ★ 严格（字面读自 GUIDE/INDEX） |
| seesaw/可除性/初等因子如何构成上界链 | ★半（读自文件头注释 + related work，未逐行验证） |
| 「上界链 ≠ Paley–Wiener 墙，是同一临界线的两条路」 | △ 推断（基于「解析 vs 代数」的路线对比，需读 `Kernels` 与 `ElementaryDivisors` 细节才能严格化） |

---

## 六、一句留给方向 C

方向 A 的结论正好强化方向 B/C 的猜想：证明把「正性的核」换成了「theta lift 链的大小」，而大小的可算性来自**有限**的 p-adic 可除性与初等因子——「正性不被需要」与「绕开 Paley–Wiener 墙」是同一个动作的两面。
