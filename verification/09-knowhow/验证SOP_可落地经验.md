# 验证 SOP · 可落地经验

> 来源：RH/VERIFY 项目收尾阶段经验总结，提炼为可执行 SOP。已同步形成项目技能 `rh-verify-sop`（位于 `.trae/skills/rh-verify-sop/SKILL.md`）。
> 日期：2026-11-25

## 铁律（违反即中止）

1. `main` 永不提交，恒等于上游 SHA `7cbf7a0c32fca1badf05931879a37c3f8a2b03b4`。
2. 自撰材料一律进 `custom` 分支的 `verification/`。
3. `src/` 任何分支都不碰。

## 隐私红线

- 对外产物与站点只写 IP47 / IP121 代号。
- 禁真实 IP、禁城市名（华南/华东等）、禁云厂商实例规格串。
- 仓库内文档同样不落真实 IP；真实 IP 与 SSH key 从记忆或用户处取。

## 1. 数据口径核实（发布前必做）

- 每个数字回原始产体验证，不沿用旧摘要 / 旧页面数字。
- 模块数 = 在 IP121 实测 `find .lake/build/lib/lean -name '*.olean' | wc -l`。
- 一致率 = 两机各自对选定模块算 sha256，逐项比对，只统计两机共有的模块。
- 发现不符：立即改数字，并如实向用户报告口径变化。

## 2. 隐私横展开（改一类问题，扫全站）

- 改「城市名 / 规格 / 真实 IP」任一后，对 `site/*.html` 与全部产物文件 Grep 复扫，确认 0 命中。
- 关键词示例：`华南|华东|华北|阿里云|腾讯云|ecs|u1`。

## 3. 产物落盘（sha256 对应真实文件）

- 页面清单里的 sha256 必须对应真实存在的文件。
- 产物散落 IP47 `/data/` 与 IP121 `/data/grh-artifacts/`：先全盘搜，再归集，核对 sha256 一致后才写进页面。
- 「可下载」= 归集打包后发 GitHub Release（tag `artifacts-YYYY-MM-DD`），页面链接指向 release 下载直链。

## 4. Git SOP

- push 前必报待推清单（分支 / commit / 内容），获用户确认后才 push。
- 「执行」= 只本地 commit；「推送」= 明确授权。
- push 后核 `ahead 0` / `behind 0`。
- gh-pages 部署序列：`git worktree add -f <tmp> gh-pages` → 复制 `site\*` → `git add -A && git commit` → push → `git worktree remove <tmp>`。

## 5. Lean 重跑规避

- `lake lean` 会触发全量 replay（数千模块，数十分钟级），生成产物前先搜现有 `.out` / `.json`。
- 命中且 sha256 与页面一致 → 直接拉取，不重算。

## 6. PowerShell 远程脚本

- 经 ssh 的 here-string 里 `cut -d" "` 定界符会被转义层吃掉 → 改为直接输出完整 sha256 行，本地取首个 token 解析。
- 多行远程脚本用单引号 here-string `@'...'@`；外层避免嵌套双引号。
