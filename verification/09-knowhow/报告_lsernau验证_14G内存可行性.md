# 报告：lsernau/grh-lean 在 IP121 的验证与 14G 内存可行性

> 日期：2026-11-28 · 范围：服务器收敛 + IP121 升级 + lsernau/grh-lean（compact 版）构建验证
> 性质：对第三方精简版 RH 证明（`lsernau/grh-lean`）在保留机 IP121 上的可验证性评估，附带本次过程的关键技术发现与经验。

---

## 一、背景与目标

在 RH/VERIFY 核心验证「终态」、释放按量计费的 IP47 之后，评估第三方精简版仓库 [`lsernau/grh-lean`](https://github.com/lsernau/grh-lean) 能否在唯一保留机 **IP121（8 vCPU / 14G / 140G）** 上完成验证。

> 前序：Sernau 精简版已在 IP47（16vCPU / 128G）完成编译 + 公理审计（见 `verification/01-readings/读解_P0_Sernau精简版编译与公理审计.md`）。本文新增——在 IP121（8vCPU / 14G）上验证「14G 内存下同样可跑通」，并沉淀服务器收敛与工具链安装经验。

核心问题：**14G 内存下，「DAG + 受控并行 + 依赖分层」策略能否规避单机内存瓶颈？**

---

## 二、执行过程

| 步骤 | 动作 | 结果 |
|---|---|---|
| 1 | 释放 IP47 前归档 | A 类 42 文件 36.79MB + `full_build_stdout.log` gzip 625MB + 源码在 git |
| 2 | IP121 新增 100G 独立盘 | `/dev/vdc` → ext4 → 挂载 `/data/lean`，写 fstab |
| 3 | 装 Lean 4.35.0 | gh-proxy 下载 594MB tarball → `/opt/lean-4.35.0` → `elan toolchain link` |
| 4 | clone lsernau/grh-lean | gh-proxy 代理，compact 版 **794 模块**（76K 行） |
| 5 | 拉 Mathlib cache | `lake exe cache get` → 9030 文件从 `cache.mathlib.org` |
| 6 | 全量构建 + 内存监控 | `lake build`（默认 8 并发）+ 10s 采样监控 |

---

## 三、关键结果

| 指标 | 实测值 |
|---|---|
| 构建结果 | ✅ **"Build completed successfully (9843 jobs)"** |
| **峰值内存（used）** | **8.98 GB**（8982 MB） |
| 峰值单进程 RSS | 7.3 GB（7306 MB） |
| 峰值时剩余内存 | ~5 GB |
| Swap | 全程 **0** |
| 默认并发 | 8（lake 5.0.0 全核） |
| **公理审计** | ✅ 5 个定理均仅依赖 `[propext, Classical.choice, Quot.sound]` |

**结论：14G 下完全可行，且无需限并发、无需升级内存；「仅 3 条公理」声明经 `#print axioms` 复核成立。**

---

## 四、关键技术发现

### 1. lake 5.0.0 移除了 `-j` 并发参数

`lake build -j 4` 报 `unknown short option '-j'`；`lake --help` 中无 jobs/threads 选项，默认按 CPU 核数全并发（IP121 起 8 个 lean 进程）。

### 2. olean 通过 mmap 共享，内存不是「并发 × 单进程」叠加

8 个并发 lean 进程每个 RSS ~6GB，但 `free` 实际 used 只有 ~7-9GB。原因是 Mathlib 的 olean 被 mmap 内存映射，8 个进程**共享同一份只读映射**，唯一内存 ≈ olean 集合大小，而非 8×6GB。

这推翻了「4 并发 × 2-3GB = 8-12GB」的保守估算——实际更乐观。

### 3. 峰值出现在中后段重模块层，末段 Main 反而很快

`Main` 模块仅 5.5s、`New.Main` 19s；峰值内存（8.98GB）出现在 Lib/New 重模块层（约 13:09）。末段最重依赖模块构建时内存已回落。

### 4. 国内服务器下载 Lean 工具链的正确姿势

- `releases.lean-lang.org` 直连：302 → `release-assets.githubusercontent.com`（被墙），超时。
- 正确做法：走 **gh-proxy 代理 github.com 的 release URL**（`https://gh-proxy.com/https://github.com/leanprover/lean4/releases/download/v4.35.0/lean-4.35.0-linux.tar.zst`），594MB 仅 47s。
- gh-proxy **不代理** `releases.lean-lang.org` 域名（返回 404），只能代理 github 系域名。

---

## 五、经验教训

1. **先实测再估算**：用「自己项目重模块」（GelfandPs 6.5GB 单线程）做上界是保守估计，但 lsernau 模块更小，实际峰值更低。探针式验证（跑通构建 + 监控内存）比盲目升配更省成本。

2. **Lean 的 olean mmap 共享是内存评估的关键**：并发构建的内存瓶颈取决于「唯一 olean 集合大小」，而非「并发数 × 单进程内存」。这是「14G 够跑」的根本原因。

3. **lake 版本差异要现场确认**：`-j` 参数在新版本移除。评估前先 `lake --help` 确认参数，别沿用旧版本假设。

4. **国内服务器的 GitHub 访问套路**：
   - git clone 直连 → TLS reset（`GnuTLS recv error -110`），走 `gh-proxy.com` 前缀即可。
   - 工具链/资产下载 → 找 github release 的真实 URL，再套 gh-proxy。
   - Mathlib cache 走 `cache.mathlib.org`，国内可直接访问（无需代理）。

5. **PowerShell → SSH 的 `$` 转义坑**：含 `$` 变量的复杂 bash 命令经 PowerShell 双引号传 SSH 会出错（`blkid` 被本地解析、bash 报 `unexpected EOF`）。正确做法是写脚本文件 `scp` 过去再执行。

6. **监控脚本要能自动收尾**：用 `while pgrep -f 'lake build'` 循环 + 记录 running peak，构建结束自动写 `BUILD_DONE peak_mem=...`，避免人工盯。

---

## 六、后续建议

1. **公理审计**：✅ 已完成。`lake env lean scripts/PrintAxioms.lean` 输出 5 个定理均仅依赖 `[propext, Classical.choice, Quot.sound]`，与 README 声明逐字一致。
2. **落盘归档**：把本次验证结果（构建成功 + 公理审计）归档到 `verification/`（如需，报待推清单后再 push custom）。
3. **保留物**：IP121 的 100G 盘（`/data/lean`）已装好 Lean 4.35.0 + Mathlib cache + lsernau 产物，可直接复用；无需再升内存。

---

## 附：环境速查

| 项 | 值 |
|---|---|
| IP121 | 8vCPU / 14G / 40G+100G 数据盘 |
| Lean | 4.35.0（`/opt/lean-4.35.0`，elan 默认）+ 4.33.1（`/opt/lean-4.33.1`） |
| lsernau | `/data/lean/grh-lean/grh-compact`（794 模块） |
| 构建日志 | IP121 `/tmp/build2.log` |
| 内存监控日志 | IP121 `/tmp/mem_peak.log` |
