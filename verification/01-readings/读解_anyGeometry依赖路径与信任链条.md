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

## 信任链条五行表

| 层 | 本项目的位置 | 验证方式 |
| :-- | :-- | :-- |
| 命题 | 证明 Mathlib 的 `RiemannHypothesis`（与教科书 RH 的等价由 Mathlib 定义保证，非本项目所验） | 类型检查等价（方案 A） |
| 公理 | 仅依赖 Mathlib 3 条公理：propext / Classical.choice / Quot.sound | `#print axioms`（待实测） |
| 内核 | Lean 4 内核逐项检查证明项类型正确性 | 编译 0 error |
| 定义 | 证明内部定义是否名副其实（如 `anyGeometry` 恒真，内核不检查） | 未做（需追证明项） |
| TCB | Lean 4 内核本身的可信基 | 不在本项目范围 |
