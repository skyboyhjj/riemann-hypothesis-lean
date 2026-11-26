# leanchecker 定向内核重放 · 结果

> 阶段 3.5 · lean4checker 独立内核重放（CocoSgt README 第 3 步）
> 日期：2026-11-26
> 结论：**30/30 模块全部通过内核重放，0 失败** —— 未发现 elaborator / metaprogram 构造不一致 Environment 的痕迹。

---

## 一、这一步在排除什么

Lean 证明有两条「构造路径」：

1. **elaborator 路径**：用户写的高层语法（`macro` / `elab` / `syntax` / `tactic`）被 elaborator 展开成内核原语，再交给内核检查。
2. **metaprogram 路径**：运行在 `MetaM` / `CoreM` 里的元程序，可用 `addDecl` 直接往 `Environment` 塞声明（`.defnDecl` / `.thmDecl` 等）。

内核只保证「塞进来的声明类型正确」，不保证「塞进来的声明是 elaborator 从源码正常展开得到的」。一个带 `unsafe` 的元程序理论上可以 `addDecl` 一个恒真占位符，把真定理偷换掉。

**leanchecker**（Lean 4.28+ 内置）用内核**重放 `.olean`**，检测这种「environment hacking」——即 metaprogram 构造的 `Environment` 与内核自己重放的结果不一致。它是**同内核**重放器，不是独立内核实现（那是 Sutherland 的 nanoda / con-leche，属 TCB 层）。

## 二、范围与方法

- 目标：30 个唯一模块 = 全部自定义 `macro` / `elab` / `syntax` 定义所在文件 + 唯一 `addDecl` 模块 `CutCptCopy.lean`。
- 方法：`lake env leanchecker <module>` 逐一重放（默认模式：重放单模块自身声明、trust 导入）。
- 环境：主编译机（IP47 代号），Lean 4.33.1，`.olean` 树在 `riemann-hypothesis-lean-2026-11-20/.lake/build/lib/lean/`。
- 脚本：`verification/04-scripts/leanchecker_targeted_replay.sh`。

## 三、结果

**30/30 通过（exit 0，内核成功重放），0 失败，0 缺 olean。**

| # | 模块 | 结果 |
|--:|------|:--:|
| 1 | Formalism.EllipticTorsion.EllipticTorsionProofs.Change | OK |
| 2 | Formalism.LocalToGlobal.TorsionIntegrality.TorsionTranslationPowers.NonsingularJetNorms.NonsingularNorm | OK |
| 3 | Formalism.LocalToGlobal.IndefiniteReal.HeckeNonvanishing.Imports | OK |
| 4 | ReciprocityTheory.ReductiveGroups.ArithmeticGeometry.ExtensionDescent.Theta1 | OK |
| 5 | Formalism.LocalToGlobal.IndefiniteForms.IndefiniteTree.FunctionalLowerBoundOfConditionsNumeric | OK |
| 6 | ReciprocityTheory.ReductiveGroups.ArithmeticGeometry.DiscreteValuationRings.ExistsRosatiGen | OK |
| 7 | Formalism.HermitianCurvature.HermitianCurvatureProofs.RttUpperRelationsFromDescent | OK |
| 8 | **Formalism.HermitianCurvature.HermitianCurvatureProofs.CutCptCopy**（唯一 `addDecl` + `cpt_copy_thms` elab） | OK |
| 9 | Formalism.SharpRestriction.Divisibility.LocalNonemptiness.SubsingletonRankIndicatorIff | OK |
| 10 | Formalism.LocalToGlobal.NumberFieldFamilies.OwnStruct | OK |
| 11 | Development.WeilBound.CoreStatements.HodgeTatePoints.CcBase | OK |
| 12 | Development.WeilBound.CoreStatements.HodgeTatePoints.CbBase | OK |
| 13 | Formalism.SatakeDualWeyl.AdelicIwasawaHecke.FIwasawaC | OK |
| 14 | Development.WeilBound.CoreStatements.PadicHodgeComparison.EtaleCohomologyComparison.CechPairings.FaceMapCompSuccAboveCastSucc | OK |
| 15 | Formalism.PeriodIntegrals.UnitaryGroupMassFormula.GaussianUniqueness.MulMApply | OK |
| 16 | Formalism.PeriodIntegrals.UnitaryGroupMassFormula.DensityLemma.PFibreBoundV | OK |
| 17 | Development.EtaleCohomology.EtaleSheaves.ChasePf | OK |
| 18 | Development.AutomorphicSpectrum.Proofs.BlockDecomposition.Cup1CoboundaryMemBoundaries | OK |
| 19 | Development.AutomorphicSpectrum.Proofs.BlockDecomposition.ShuffleCup1FormulaPositiveDegree | OK |
| 20 | Development.AbelianVarietyTheory.Definitions.GaloisGeometry.NegOnePowBoundaryTermsCancel | OK |
| 21 | Development.AbelianVarietyTheory.Definitions.AutomorphicMembership.RealIoX | OK |
| 22 | Development.AbelianVarietyTheory.Definitions.AutomorphicMembership.PlaceModelImp | OK |
| 23 | Development.AbelianVarietyTheory.Definitions.AutomorphicMembership.GoodPartEq | OK |
| 24 | Development.AbelianVarietyTheory.Proofs.DivisorProofs.ExistsMeasY | OK |
| 25 | Development.AbelianVarietyTheory.Proofs.IwasawaDecomposition.RealDatumPrerequisitesUpdateModels | OK |
| 26 | Development.AbelianVarietyTheory.Proofs.IwasawaDecomposition.RingSpecNormalisedCharacterEq | OK |
| 27 | Development.AbelianVarietyTheory.Proofs.IwasawaDecomposition.RigidFrameSymmetricRatioSeries | OK |
| 28 | Development.AbelianVarietyTheory.Proofs.InertiaEigenvalues.IsClassSystem | OK |
| 29 | Development.AbelianVarietyTheory.Proofs.InertiaEigenvalues.SetupRelIffSameData | OK |
| 30 | Development.AbelianVarietyTheory.Proofs.DivisorProofs.IsProperOfFiniteType | OK |

> 原始输出：远端 `/data/lc_targeted/results.log`（30 行 `OK` + 末行 `TOTAL=30 OK=30 FAIL=0`）。

## 四、为什么「定向重放」足够，而非全量重放

- 全量重放 175,187 模块在单机 16 核上需 7–14 天（两种可行模式实测），边际价值低。
- `src/` 全量静态扫描：**0 `unsafe`、0 `implemented_by`、0 `extern`、0 `opaque`**。
- 无 `unsafe` → metaprogram **无法绕过内核**（所有 `addDecl` 必经内核 `Environment.add` 检查）。因此 environment hacking 唯一可能藏身处，就是「自定义 `macro` / `elab` / `syntax` 的展开」与「显式 `addDecl` 调用」，这恰好被本次 30 个定向模块覆盖。
- 结论：定向重放 30/30 通过，加上 0-unsafe 扫描，即封死 elaborator / metaprogram 这一环。

## 五、口径边界（重要）

1. leanchecker 是**同内核**重放，验证「元程序没有构造非法 Environment」，**不验证内核本身正确**（TCB 层，属 Sutherland 分工）。
2. 重放「成功」= 内核能逐声明重现该模块的 `.olean`；它不检验「定义是否名副其实」（如 `anyGeometry` 恒真，那是定义层缺口，已另文读解）。
3. 本次为**定向**重放（30 模块），非全量 175k 模块；其充分性由「0-unsafe 扫描」论证支撑，而非穷举。
