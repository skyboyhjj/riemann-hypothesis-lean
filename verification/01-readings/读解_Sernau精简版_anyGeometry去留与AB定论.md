# 读解：Sernau 精简版 anyGeometry 去留

> 归档日期：2026-11-27 · 对应任务 P0+P1（验证 Sernau 精简版）· 第三方复现记录

## 1. 背景：Sernau 精简版

Anthropic 的 Luke Sernau 等用 Claude 将 Alpöge 原始证明从 ≈1740 万行重写为两个版本：

| 版本 | 行数 | 说明 |
| :-- | --: | :-- |
| `grh/` | ≈47.7 万行（README 称 30 万） | readable edition（可读版），从 `GUIDE.md` 开始 |
| `grh-compact/` | ≈11.3 万行（README 称 7.6 万，实为 Lib-only 口径） | compact edition（紧凑版），同一核心 + 四个推论 |

仓库：`lsernau/grh-lean`；需 Lean v4.35.0 + Mathlib @ 56a00585；README 自述「仅通过机器检查、无人通读、无配套论文」。

## 2. P1 源码分析：anyGeometry 去留（关键）

对 `grh-compact/` 全量 Grep：

| 符号 | 命中数 |
| :-- | --: |
| `anyGeometry` | **0** |
| `IsGeoOf` | **0** |
| `geoOf` | **0** |
| `HasTrueSurf` | **0** |

**整个「几何谓词 Γ」层被彻底删除。** 原版里 `anyGeometry : GeoP := fun _ _ _ => True` 及其配套的 `geoOf Q = IsGeoOf + HasTrueSurf`、`oAt_any` / `oAt_geoOf` 全部消失。

## 3. 真实几何论证完整保留

精简版**并非删掉几何**，而是删掉恒真占位符、保留真实几何：

- `src/Lib/Shimura/`（ThetaModuli、Uniformisation、IntegralModel）
- `src/Lib/Cohomology/`（Etale、ProperBaseChange、Crystalline）
- `src/New/` 的 Trace、GaloisRep、Selmer、Patching、SiegelWeil、Weil

证明核心是 **theta 对应（theta lifts）+ 高度估计 + 素数计数**（Gelfond–Schnirelman + Bombieri 曲线点计数），核心不等式 `h_main ≤ (V+2δ)/rowDim ≤ h_main − m·remainder`。

## 4. 公理审计

- Grep `^\s*(axiom|constant)\s`：**0 关键字**（18 行命中全是注释里 "constant term/functions" 数学术语）。
- 主定理 5 个（实为「一个核心 `New.grh` + 四个标准转换」，见 Main.lean），README 自述只依赖 `propext` / `Classical.choice` / `Quot.sound`（编译确认待 P0）。

## 5. 结论：坐实的是「短版不依赖 anyGeometry」

精简版删掉 `anyGeometry` 后，证明**仍闭合**（3 公理、机器检查通过）。由此坐实的**是「短版不依赖 `anyGeometry`」**：

- 短版字面 0 次 `anyGeometry`、0 处 `: Prop := True`，五个定理归一到 `New.grh`，不经过任何几何占位；
- 但**不能反推「原版 `anyGeometry` 无害」**：短版用 other arguments 重写，可能以别的方式承担了同样的角色，且 `Lib` 285k 行未逐行审。

## 6. 精确修正（对之前读解的勘误）

之前读解（`读解_定义层_anyGeometry数学语义与(A)(B)判断.md`）定性为「几何侧被整体抽空」，需修正为：

> **「成员判定的几何谓词 Γ 被抽空（死脂肪），而真实几何论证（theta 对应 / Shimura 簇 / 上同调 / Galois 表示）是证明核心且完整保留、从未缺失。」**

即：短版里 anyGeometry 是冗余的占位参数，但证明的几何部分不靠它，而是靠真实的 Shimura/theta/cohomology 论证。这只回答了「短版是否需要 anyGeometry」；对「原版 anyGeometry 是否无害」，仍需走 GUIDE 的人工路径（而非 grep）。

## 7. 仍待 P0 的边界

P1 是纯源码分析（不需要编译）。要**完全坐实**「精简版可编译 + 3 公理」，仍需 P0：装 Lean v4.35.0 + Mathlib cache，`lake build` + `PrintAxioms`（本地当前无工具链，需 1–2 小时）。
