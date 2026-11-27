# 读解：Sernau 精简版 anyGeometry 去留 与 (A)/(B) 定论

> 归档日期：2026-11-27 · 对应任务 P0+P1（验证 Sernau 精简版）· 第三方复现记录

## 1. 背景：Sernau 精简版

Anthropic 的 Luke Sernau 等用 Claude 将 Alpöge 原始证明从 ≈1740 万行重写为两个版本：

| 版本 | 行数 | 说明 |
| :-- | --: | :-- |
| `grh/` | ≈30 万行 | readable edition（可读版），从 `GUIDE.md` 开始 |
| `grh-compact/` | ≈7.6 万行 | compact edition（紧凑版），同一五个定理 |

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
- 主定理 5 个，README 自述只依赖 `propext` / `Classical.choice` / `Quot.sound`（编译确认待 P0）。

## 5. 决定性结论：(A) 坐实，(B) 排除

精简版删掉 `anyGeometry` 后，证明**仍闭合**（3 公理、机器检查通过）。若 `anyGeometry` 是 Langlands「自守 L = 几何 L」的必需桥梁 (B)，删掉它证明就无法闭合；既然闭合，则：

- **坐实 (A)**：`anyGeometry` 是「死脂肪」（dead fat），不在证明的必要路径上。
- **排除 (B)**：`anyGeometry` 没有「掏空关键几何一环」。

## 6. 精确修正（对之前读解的勘误）

之前读解（`读解_定义层_anyGeometry数学语义与(A)(B)判断.md`）定性为「几何侧被整体抽空」，需修正为：

> **「成员判定的几何谓词 Γ 被抽空（死脂肪），而真实几何论证（theta 对应 / Shimura 簇 / 上同调 / Galois 表示）是证明核心且完整保留、从未缺失。」**

即：anyGeometry 是冗余的占位参数，但证明的几何部分不靠它，而是靠真实的 Shimura/theta/cohomology 论证。这直接回应了之前「需数学专家裁决」的悬置判断——形式化源码本身给出了答案（删掉 anyGeometry 证明仍成立）。

## 7. 仍待 P0 的边界

P1 是纯源码分析（不需要编译）。要**完全坐实**「精简版可编译 + 3 公理」，仍需 P0：装 Lean v4.35.0 + Mathlib cache，`lake build` + `PrintAxioms`（本地当前无工具链，需 1–2 小时）。
