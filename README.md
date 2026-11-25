# RH / VERIFY · 验证站点源码

本分支是 [RH / VERIFY 验证站点](https://skyboyhjj.github.io/riemann-hypothesis-lean/) 的网页源码（gh-pages），通过 GitHub Pages 发布。

## 这是什么

黎曼猜想（Riemann Hypothesis）Lean 证明的**第三方复现与验证**站点。仓库 fork 自 [CocoSgt/riemann-hypothesis-lean](https://github.com/CocoSgt/riemann-hypothesis-lean)（上游 = Alpöge × Claude 的证明）。

## 分支职责

| 分支 | 内容 |
|---|---|
| `gh-pages`（本分支） | 站点网页源码，GitHub Pages 发布源 |
| `custom`（默认分支） | 自撰验证材料，统一在 `verification/` |
| `main` | 证明源码镜像，恒等于上游，永不改动 |

## 目录结构

- `index.html` — 首页
- `reproduction.html` — 独立复现
- `structure.html` — 结构消化
- `machine.html` — 机器遥测
- `results.html` — 结论
- `crosscheck.html` — 双机交叉
- `log.html` — 验证日志
- `downloads.html` — 产物下载
- `css/` — 站点样式
- `.nojekyll` — 关闭 Jekyll 处理

## 在线访问

<https://skyboyhjj.github.io/riemann-hypothesis-lean/>

## 参考

[proveriemannhypothesis.github.io](https://proveriemannhypothesis.github.io/)
