# 第三方验证记录（verification/）

本目录是 Alpöge × Claude《黎曼猜想 Lean 证明》的**第三方复现与读解**。

**代码不在这里** —— 证明代码是仓库根目录的 `src/`，与本目录互不相干，且任何分支都不改动 `src/`。

## 三条铁律（违反即中止）

1. `main` 永不提交，恒等于上游 SHA `7cbf7a0c32fca1badf05931879a37c3f8a2b03b4`。
2. 一切自撰材料（读解 / 附录 / 脚本 / 规划 / artifact）都在 `custom` 分支的 `verification/` 下。
3. `src/` 永不改动（任何分支都不碰）。

## 目录结构

| 目录 | 内容 |
|------|------|
| `01-readings/` | 读解：对证明各环节的逐层核验结论 |
| `04-scripts/` | 可复算脚本（Lean 审计脚本 + leanchecker 重放脚本及结果） |
| `09-knowhow/` | 方法论与经验沉淀（SOP、溯源方法、时间线/硬件对比） |

## 核心结论（截至 2026-11-26）

| 验证层 | 结论 |
|--------|------|
| 全量编译 | 175,187 模块（level 0 的 5,927 + level 1–202 的 169,260）0 错误，61.54h |
| 公理审计 | 五终定理仅依赖 `propext` / `Classical.choice` / `Quot.sound`（3 条标准公理） |
| 语句审计 | `RiemannHypothesis`（Mathlib）与 `RiemannZetaZerosOnLine`（Statements）逐字一致 → 所证即 RH |
| 内核重放 | 编译 0 error；leanchecker 定向内核重放 30/30 通过（排除 metaprogram environment hacking） |
| 双机交叉 | 20 候选 → 14 可比 → 14/14 逐字节一致 → 6 不可比（olean 路径嵌入） |
| 定义层 | `anyGeometry` 恒真（`fun _ _ _ => True`）且在证明链上；真实几何 `IsGeoOf` 从不进链 |

> 各层的详细依据见对应目录下的读解文件；「定义层」是本项目相对内核检查的**增量价值**所在——内核保证类型正确，但检查不到「定义是否名副其实」。

## 隐私红线

对外产物与站点只写 **IP47 / IP121 代号**，不落真实 IP、城市名、云厂商实例规格串。

## 站点

验证 microsite：<https://skyboyhjj.github.io/riemann-hypothesis-lean/>
