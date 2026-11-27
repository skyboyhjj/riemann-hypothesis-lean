#!/usr/bin/env python3
# RH/VERIFY 结构测绘产物重生成（全文口径 + Unicode 安全 import 解析）
import os
from collections import Counter

SRC = '/data/riemann-hypothesis-lean-2026-11-20/src'
HEAVY_ORIG = '/tmp/heavy_orig.txt'   # 既有 heavy_in_closure.txt（第 2 列 = 95 个重文件名单）
OUT_DIR = '/data/analysis'
os.makedirs(OUT_DIR, exist_ok=True)

# 1. 收集模块
mods = {}
for root, dirs, files in os.walk(SRC):
    for f in files:
        if f.endswith('.lean'):
            p = os.path.join(root, f)
            rel = os.path.relpath(p, SRC)
            mods[rel[:-5].replace(os.sep, '.')] = p
src_mods = set(mods.keys())
N = len(mods)

# 2. 提取 import：全文读取 + split（含 ₂ 等多字节标识符）
deps = {}          # mod -> set（去重）
fanin = Counter()  # 不去重 fan-in
for m, p in mods.items():
    with open(p, 'rb') as fh:
        data = fh.read().decode('utf-8', errors='ignore')
    ds = set()
    for line in data.splitlines():
        s = line.strip()
        if s.startswith('import '):
            s = s.split('--')[0].strip()
            for name in s[7:].split():
                if name in src_mods:
                    ds.add(name)
                    fanin[name] += 1
    deps[m] = ds

edges_dedup = sum(len(ds) for ds in deps.values())
edges_raw = sum(fanin.values())

# 3. Main 传递闭包（去重）
closure = set()
stack = ['Main']
while stack:
    m = stack.pop()
    for d in deps.get(m, set()):
        if d not in closure:
            closure.add(d)
            stack.append(d)

# 4. 重文件（95 个，>100s 按层构建口径），沿用既有产物名单，仅重算其 fan-in
heavy_names = []
with open(HEAVY_ORIG) as fh:
    for line in fh:
        parts = line.rstrip('\n').split('\t')
        if len(parts) >= 2:
            heavy_names.append(parts[1])

n_in = len(closure)
n_out = N - n_in
pct = n_in / N * 100
pct_out = n_out / N * 100

def fmt(n):
    return f"{n:,}"

# 5. 写产物
stats = f"""==============================================================
Main 传递依赖闭包 · 统计
==============================================================
  起点模块        Main
  全项目模块      {fmt(N)}
  闭包内模块      {fmt(n_in)}
  闭包占比        {pct:.4f}%
  未被 Main 依赖  {fmt(n_out)}（{pct_out:.4f}%）

  重文件清单      共 {len(heavy_names)} 个
  闭包内命中重文件 {sum(1 for h in heavy_names if h in closure)} 个
                    ← 这批就是核心论证所在，优先读

  输出文件：
    /data/analysis/main_closure.txt      闭包全部模块（fan-in\t模块）
    /data/analysis/pivot_modules.txt     前 100 枢纽（按 fan-in）
    /data/analysis/heavy_in_closure.txt  闭包内重文件

  下一步：对 pivot_modules.txt 里的前 30–50 个模块，提取定理声明
          （grep '^(theorem|lemma)' 即可），那就是论证骨架的候选。
"""
with open(os.path.join(OUT_DIR, 'closure_stats.txt'), 'w') as fh:
    fh.write(stats)

# 5.2 main_closure.txt + pivot_modules.txt（闭包内，fan-in 降序）
ordered = sorted(closure, key=lambda m: (-fanin[m], m))
with open(os.path.join(OUT_DIR, 'main_closure.txt'), 'w') as fh:
    for m in ordered:
        fh.write(f"{fanin[m]}\t{m}\n")
with open(os.path.join(OUT_DIR, 'pivot_modules.txt'), 'w') as fh:
    for m in ordered[:100]:
        fh.write(f"{fanin[m]}\t{m}\n")

# 5.3 heavy_in_closure.txt（95 个重文件，fan-in 降序）
heavy_sorted = sorted(heavy_names, key=lambda m: (-fanin[m], m))
with open(os.path.join(OUT_DIR, 'heavy_in_closure.txt'), 'w') as fh:
    for m in heavy_sorted:
        fh.write(f"{fanin[m]}\t{m}\n")

# 6. 验证摘要
print("=== 验证摘要 ===")
print(f"总模块数 N = {N}")
print(f"边数(去重) = {edges_dedup}")
print(f"边数(不去重) = {edges_raw}")
print(f"闭包内模块 = {n_in}")
print(f"闭包外模块 = {n_out}")
print(f"闭包占比 = {pct:.4f}%")
print(f"重文件数 = {len(heavy_names)}")
print(f"闭包内命中重文件 = {sum(1 for h in heavy_names if h in closure)}")
print("重文件 fan-in 最高（不去重）:")
for m in heavy_sorted[:3]:
    print(f"  {fanin[m]}\t{m}")
print("fan-in Top 8（不去重）:")
for m in ordered[:8]:
    print(f"  {fanin[m]}\t{m}")
