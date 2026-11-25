# 读解：anyGeometry 依赖路径与信任链条

> 归档日期：2026-11-25 · 对应改1版任务清单 0.4 / 0.5 · 第三方复现记录

## 0.4 source-scan 结果

对 `src/` 全量扫描（175,187 模块，git 追踪口径），结论如下，全部 0 命中：

| 扫描项 | 命中数 | 含义 |
| :-- | --: | :-- |
| `@[implemented_by]` | 0 | 无「声明-可执行实现分离」 |
| `@[extern]` | 0 | 无「外部 C/C++ 实现黑盒」 |
| `axiom` 声明 | 0 | 未自引公理 |
| `constant` 声明 | 0 | 未自引常量 |
| `opaque` 声明 | 0 | 无不透明定义 |
| `sorry` / `admit` | 0 | 无未完成证明 |

> 注：grep 到的 `constant` 命中均为 `PreconnectedSpace.constant` 等方法名（拓扑「连通空间连续函数为常值」定理），非 `constant` 关键字声明。

**结论**：项目 `src/` 是纯 Lean 内完整实现，公理全部来自 Mathlib（3 条），与「只依赖 3 条公理」判据自洽。

## 0.5 anyGeometry 依赖路径分析

### 问题来源

Frank Chu（dev.to 评论）开放问题：Main.lean 依赖路径走不走 `anyGeometry`。

### 定义

```lean
-- Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/OverIx.lean:19
def anyGeometry : GeoP := fun _ _ _ => True   -- 恒真几何谓词
```

其中 `GeoP := ∀ D, Core D → DivX D → Prop`；`geoOf Q` 才是「真几何条件」。

### 三步结果

1. **定位**：24 文件、162 次文本出现（含定义行与注释；结构测绘「调用」口径为 118）。
2. **Main 闭包求交**：实测 Main 闭包 = 175,186 模块，**覆盖 src 全部 175,187 模块**（唯一未入闭包的是 Main 自己；394 个 `₂` 文件全在闭包内）。故「anyGeometry 的 24 文件 24/24 在闭包内」是**平凡事实**——闭包几乎覆盖全模块，不能作为「证明项依赖 anyGeometry」的证据。
3. **性质**：全部为**显式参数**（`geoCl anyGeometry`、`movable_geometric … anyGeometry`），**零 instance 字段**（无 `[anyGeometry]`、无 `instance … anyGeometry`）。

### 结论

「anyGeometry 的 24 文件全在 Main 闭包内」**不能推出**「证明项依赖 anyGeometry」：文件被 import 是**必要条件而非充分条件**（方向 `Closure(Main) ⊇ Consts(proof)` 单向），且 Main 闭包覆盖全部模块，故「在闭包内」几乎总是成立。要回答 Chu 的问题，须用**常量依赖判据**：元编程取 `riemannHypothesis` 证明项、递归展开 `.const` 闭包，查是否含 `anyGeometry`（脚本 `verification/04-scripts/AuditAnyGeometry.lean`，需 Main 编译完成后执行）。

已证实的三个事实：`anyGeometry` 恒真（`fun _ _ _ => True`）、24 使用文件全在闭包内、零 instance 字段。`anyGeometry` 是否「顶替」了本应出现的 `geoOf Q`，仍待常量依赖判据闭合。

## 0.6 直接层常量判据（实测 · 轻量版）

原方案 `AuditAnyGeometry.lean` 对 `riemannHypothesis` 证明项做完整传递闭包 BFS，因闭包过大被 OOM（RSS ~118 GB）杀掉。改为轻量判据：只取证明项**直接**常量 + **一层**展开，不递归全闭包。

实测结果（`AuditAnyGeometryLite.lean`，2026-11-25）：

```
直接常量: [rhOfAll]
一层展开后常量数: 2
一层展开中含 'anyGeometry': 0
```

证明链顶层结构（源码）：

```lean
-- Main.lean:4
theorem riemannHypothesis : RiemannHypothesis := rhOfAll
-- Supplements/Kernels/MainTheorems.lean:9
theorem rhOfAll : RiemannHypothesis := Formalism.VW.rh_of_every allChi
```

即 `riemannHypothesis → rhOfAll → Formalism.VW.rh_of_every allChi`，**前两层不含 anyGeometry**。anyGeometry 仍在更深层（`AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/` 的 `*_alt` 中间引理），须受控分层追踪（见 0.7）才能定论是否「顶替 geoOf Q」。

## 0.7 受控分层追踪（实测 · 源码级）

BFS 全闭包与去重版分层 BFS 均因证明链传递闭包过大而不可行（OOM 118 GB，或 10+ 分钟无输出）。改用**源码级证明链追踪**（沿 `:=` 逐级展开引用），完整还原 `riemannHypothesis` → `anyGeometry` 的依赖路径：

```
riemannHypothesis (Main.lean:4) := rhOfAll
rhOfAll (Supplements/Kernels/MainTheorems.lean:9) := Formalism.VW.rh_of_every allChi
rh_of_every (Formalism/GammaFactorNonvanishing/CritLine.lean:29)  -- 薄壳：应用到平凡特征 N=1
allChi (MainTheorems.lean:7) := UpperTheory.FinalTheorems.everyCharacter
everyCharacter (CharacterBoxes/MainConclusion.lean:10) := every_character_of_literature_of_vWin …
every_character_of_literature_of_vWin (ThirdPlaceSeries/EveryCharacterOfLiteratureOfVWin.lean:810)
  └─ 直接调用 SelfIntersectionVolumeEstimates.topCovolSlim2_use_alt_alt
topCovolSlim2_use_alt_alt (ThirdPlaceSeries/TopCovolSlim2Use.lean:16)
  └─ 调用 topCovolG_alt_alt
topCovolG_alt_alt → … → memberE_closing_alt_alt / member_exists_baseLattice_alt / large_unramified_exponent_bundles_exist_alt 等
  └─ 这些 `*_alt` / `*_alt_alt` 定理的结论里含 `geoCl anyGeometry`
anyGeometry (AbelianVarietyTheory/Definitions/AutomorphicMembership/OverIx.lean:19) := fun _ _ _ => True
```

**结论：`anyGeometry` 确认在 `riemannHypothesis` 的证明链上**，不是死代码。Chu 的问题答案是「依赖路径走了 anyGeometry」。

**定性结论：`anyGeometry` 构成「实质性偷懒」**（见 0.8），非无害占位符。

## 0.8 语义定性：lam 与几何正交，偷懒是实质性的

### 语义基础

| 符号 | 定义 | 语义 |
| :-- | :-- | :-- |
| `GeoP` | [OverIx.lean:14](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/OverIx.lean#L14) `∀ D, Core D → DivX D → Prop` | 几何谓词 |
| `geoOf Q` | [OverIx.lean:16](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/OverIx.lean#L16) `(∃c>0, IsGeoOf (Q D) J c X) ∧ HasTrueSurf X` | **真实几何** |
| `anyGeometry` | [OverIx.lean:19](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/OverIx.lean#L19) `fun _ _ _ => True` | **恒真几何（免费）** |
| `geoCl Γ` | [NotGeoClFalse.lean:26](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/NotGeoClFalse.lean#L26) `GeoCl Γ`（base/step 归纳闭包） | 几何闭包；`geoCl anyGeometry` 亦恒真 |

### 形式化证据（三层）

1. **Γ 是「成员判定」的几何成分，证明链统一用 anyGeometry 填满**：`Parameters = {R,N,S,Γ}`，Γ 经 [Parameters.s](src/Development/AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/CoreAltAltBis.lean#L25) 的 `OX Γ` 进入 `OAt Γ`（字段 `geo : Γ … X` + `lam : LamAre …`）。`*_alt` 系列 55 处全部以 `parametersOfExtension N SExt.none (geoCl anyGeometry)` 实例化。
2. **`IsGeoOf`（真实几何核心谓词）从不进证明链**：全 src 仅 12 处（定义层 [LargeFor.lean:78](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/LargeFor.lean#L78) + `geoOf` 定义 + 辅助引理 NotLamAreShift）。`memberE_closing` / `topCovolSlim2_use_alt_alt` / `every_character_of_literature_of_vWin` 无一引用。
3. **`oAt_any` 与 `oAt_geoOf` 对照写死「免费化」**：[oAt_any](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/NotLamAreShift.lean#L152-L155) 只需 `R3.Lam3`，`geo` 字段直接 `trivial`；[oAt_geoOf](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/NotLamAreShift.lean#L157-L161) 需 `R3.Lam3` **+ 独立假设 `IsGeoOf Q`**。

### 核心判断：lam 不蕴含几何

- `Lam3` [StableIffCarrierEq.lean:262](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/StableIffCarrierEq.lean#L262) / `LamAre` [OverIx.lean:33](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/OverIx.lean#L33) 是**谱/lam 侧**条件（`isot` 等距、`lamP` 参数、`nRows0`、`span`、`finrank`）。
- `IsGeoOf` [LargeFor.lean:78](src/Development/AbelianVarietyTheory/Definitions/AutomorphicMembership/LargeFor.lean#L78) 是**几何/算术侧**构造（`Top` 模型、`FamOver` form 族、`Φ.Reads` 几何读数、`record`、`vdd = vDiff`）。
- 两者**正交**：`oAt_geoOf` 把 `IsGeoOf` 作为 `Lam3` 之外的独立假设，即 lam 不自动给出几何。
- 证明链只用 `oAt_any`（lam + 免费几何），**从未兑现 `IsGeoOf`**。

### 定论

`anyGeometry` 的恒真不是无害占位符，而是把「成员判定的几何成分」从真实几何（`geoOf Q = IsGeoOf + HasTrueSurf`）替换为恒真，且**无桥接步骤**把 anyGeometry 成员转化为 geoOf 成员。**RH 证明在「真实几何」这一环是空的**——除非作者在数学上另有「lam 自动蕴含几何」的独立论证（代码中未见，`IsGeoOf` 从不进证明链）。

### 泄漏追踪（最终一跳）：anyGeometry 不语法污染 EveryCharacter，但真实几何桥接缺失

追 `every_character_of_theta_integrals_local_matching`（[SiegelEisensteinSecondTermHypotheses.lean:69](src/Development/AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/SiegelEisensteinSecondTermHypotheses.lean#L69)，`EveryCharacter` 的直接生产点）确认：

- 其证明体调用 `every_character_of_green_v_win` + `nonempty_hyps_definite_side_of_closed_bound`（[同文件:44](src/Development/AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/SiegelEisensteinSecondTermHypotheses.lean#L44)）。
- `nonempty_hyps_definite_side_of_closed_bound` 的**结论**是 `Nonempty (HypsAlt S0.NL DefiniteSideCondition)`，但证明体 **3 处使用 `geoCl anyGeometry`**（L60 `open_and_linked_of_stronger_extension_alt`、L63 `rowFun_at_gridA_alt`、L67 `linked_bundles_l3_of_open_alt`）。
- `DefiniteSideCondition` 的定义（[DefiniteSideCondition.lean:25](src/Development/AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/DefiniteSideCondition.lean#L25)）**不含几何谓词 Γ**——只依赖 `DivTied3` / `RowsU` / `packageOfPrimitiveLinks` / `ofRecord` / `letterOf` 等「除子/行/链接」结构。

**两条精确结论**：

1. **语法上不污染**：anyGeometry 被「消化」在成员链内部，`DefiniteSideCondition` 与最终 `EveryCharacter` 均不含 Γ。因此「Lean 定理被写错成任意几何版 RH」**不成立**——RH 命题（EveryCharacter）是干净的纯解析命题，Lean 内核也验证其类型正确（仅 3 条标准公理）。

2. **语义上仍是实质缺口**：anyGeometry 恒真在证明中**被实质使用**（`oAt_any` 用 `trivial` 免费构造 `geo` 字段、`divEx_geoCl` 用 `geoCl_of o.geo` 提升闭包），而真实几何 `IsGeoOf` 从不进链。这意味着「成员/束/链接」机制的**几何成分**全程恒真，证明**从未建立「任何算术几何对象是真实几何」**这一 Langlands 对应「自守 L = 几何 L」的桥梁。

**DivTied3 追踪（已闭合）**：读 `DivTied3`（[DivisionCompatibleToSub2Indef2.lean:172](src/Formalism/LocalToGlobal/Divisibility/DivisionCompatibleToSub2Indef2.lean#L172)，除子绑定）、`packageOfPrimitiveLinks`（[PtKOfReal.lean:19](src/Development/AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/PtKOfReal.lean#L19)，原始链接包）、`ofRecord`（[NumbersLemmas.lean:604](src/Formalism/LocalToGlobal/Divisibility/NumbersLemmas.lean#L604)，数字记录）——三者**均不含 `IsGeoOf` / `geoOf` / `HasTrueSurf`**。`DivTied3` 全是「绑定关系」（`GrpTie`/`RowSideTie`/`ColTie`/`NumTie`/`TupTie`/`MtTie`/`ThTie`）+ 维数等式（`ranks`），是**谱/行/列/数字侧**结构，非几何侧。

**最终定性（收敛）**：

1. **语法不污染**（anyGeometry 不进入 `EveryCharacter` 命题）——确凿；
2. **真实几何缺失**（`IsGeoOf` 从不进证明链）——确凿；
3. **除子/链接结构本身也不依赖真实几何**（`DivTied3` 不含 `IsGeoOf`）——确凿。

三者合起来：证明的「几何谓词 Γ」是一个**从头到尾被恒真 anyGeometry 填充、且其真实几何版本（`IsGeoOf`）既不被要求、也不被使用**的参数。最终 `EveryCharacter` 确实不依赖 Γ，但这是因为「几何侧」被整体抽空，而非「几何侧被正确证明为真实」。

**残余判断（需数学专家，形式化无法自动闭合）**：代码无法自动区分两种解读——(A) 作者设计本就不需几何侧（anyGeometry 是正确抽象，证明可信）；(B) 真实几何是 Langlands「自守 L = 几何 L」的必需桥梁，被 anyGeometry 掏空（证明缺失关键一环）。`geoOf` / `IsGeoOf` / `oAt_geoOf` 被精确定义却**从未被兑现**，是「(B) 倾向」的强证据。这正是本项目「定义层」验证的价值：内核检查不到这一层。

## 信任链条五行表

| 层 | 本项目的位置 | 验证方式 |
| :-- | :-- | :-- |
| 命题 | 证明 Mathlib 的 `RiemannHypothesis`（与教科书 RH 的等价由 Mathlib 定义保证，非本项目所验） | 类型检查等价（方案 A） |
| 公理 | 仅依赖 Mathlib 3 条公理：propext / Classical.choice / Quot.sound | `#print axioms`（五定理实测：仅 3 条标准公理） |
| 内核 | Lean 4 内核逐项检查证明项类型正确性 | 编译 0 error |
| 定义 | 证明内部定义是否名副其实（如 `anyGeometry` 恒真，内核不检查） | 已定位恒真、在证明链上（0.7）；定性为「实质性偷懒」（0.8：lam 不蕴含几何，真实几何 IsGeoOf 不进链） |
| TCB | Lean 4 内核本身的可信基 | 不在本项目范围 |
