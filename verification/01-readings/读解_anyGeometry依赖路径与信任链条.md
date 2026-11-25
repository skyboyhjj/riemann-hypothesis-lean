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

**但「是否偷懒」仍是开放的数学判断**：anyGeometry 恒真，作为 `geoCl anyGeometry` 出现在 `*_alt` 系列中间引理的**结论**里（配合 `MemberE` / `ExBL` / `IsBuiltE` / `IsGoodE` 等非平凡性质）。这些引理用「任意几何」是否顶替了本应具体的 `geoOf Q`，需读证明体逐一定性，属语义层，非形式化判据可自动闭合。

## 信任链条五行表

| 层 | 本项目的位置 | 验证方式 |
| :-- | :-- | :-- |
| 命题 | 证明 Mathlib 的 `RiemannHypothesis`（与教科书 RH 的等价由 Mathlib 定义保证，非本项目所验） | 类型检查等价（方案 A） |
| 公理 | 仅依赖 Mathlib 3 条公理：propext / Classical.choice / Quot.sound | `#print axioms`（五定理实测：仅 3 条标准公理） |
| 内核 | Lean 4 内核逐项检查证明项类型正确性 | 编译 0 error |
| 定义 | 证明内部定义是否名副其实（如 `anyGeometry` 恒真，内核不检查） | 已定位恒真、确认在证明链上（0.7）；是否偷懒待语义判断 |
| TCB | Lean 4 内核本身的可信基 | 不在本项目范围 |
