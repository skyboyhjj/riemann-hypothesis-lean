# 读解：P0 · Sernau 精简版独立编译与公理审计

> 归档日期：2026-11-27 · 对应任务 P0 · 第三方复现记录

## 目标

把 Sernau 精简版（`grh-compact`，约 7.6 万行）的「可编译 + 仅 3 公理」从 README 自述，升级为本项目独立编译坐实。与 P1（anyGeometry 去留）合起来，构成对精简版的完整闭环验证。

## 环境（IP47 · 代号）

| 项 | 值 |
| :-- | :-- |
| 机器 | IP47（16 vCPU / 128 GiB / 1.5 TiB） |
| Lean | v4.35.0（commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`，Release） |
| Lake | 5.0.0-src+eb6cafb |
| Mathlib | commit `56a005855ea17e0b0958f73ec801ae140b0a1679` |
| 源码 | `/data/grh-lean-sernau`（gh-proxy 加速 clone） |
| 工具链路径 | `/opt/lean-4.35.0-linux`（与 4.33.1 并存，不动旧环境） |

## 过程

1. 装 Lean v4.35.0 二进制（不装 elan，避免影响现有 4.33.1）；gh-proxy 加速下载（883 MB / 74 s / ≈11.8 MB/s）。
2. clone `lsernau/grh-lean`（gh-proxy 加速，`--depth 1`）。
3. `lake exe cache get`：Mathlib 缓存 9031 文件下载解压完成。
4. `lake build`：后台 nohup（12 核），约 1 小时。
5. `lake env lean scripts/PrintAxioms.lean`：列五定理公理。

## 结果

### 编译

```
Build completed successfully (9843 jobs).
```

0 错误（仅 linter / deprecation 告警，如 `peel` → `gconvert`/`congr!`）。

### 公理审计

| 定理 | 依赖公理 |
| :-- | :-- |
| `riemannHypothesis` | propext, Classical.choice, Quot.sound |
| `riemannZeta_eq_zero_re` | propext, Classical.choice, Quot.sound |
| `LFunction_ne_zero_of_half_lt_re` | propext, Classical.choice, Quot.sound |
| `LFunction_eq_zero_re` | propext, Classical.choice, Quot.sound |
| `LFunction_eq_zero_re_of_isPrimitive` | propext, Classical.choice, Quot.sound |

五定理全部仅依赖 3 条标准公理，与上游 175,187 模块版一致。

## 结论：P0 + P1 闭环

1. **可编译**（P0）：9843 jobs 成功，0 错误。
2. **公理干净**（P0）：5 定理仅 3 条标准公理。
3. **anyGeometry 已删除**（P1）：几何谓词层 0 命中，证明仍闭合 → 坐实 (A)「死脂肪」。

三者合起来：Sernau 精简版是上游证明的诚实重写，其「可编译 + 3 公理」从 README 自述升级为独立坐实；anyGeometry 的 (A) 定论获得编译级支撑。

## 信任链条定位

P0 属「内核层」的交叉验证：对精简版（7.6 万行）独立跑一遍编译 + 公理审计，与上游（175,187 模块）的编译 + 3 公理结论互相印证。
