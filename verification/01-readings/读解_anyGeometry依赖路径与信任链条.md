# 读解：anyGeometry 依赖路径与信任链条

> 归档日期：2026-11-25 · 对应改1版任务清单 0.4 / 0.5 · 第三方复现记录

## 0.4 source-scan 结果

对 `src/` 全量扫描（175,186 模块），结论如下，全部 0 命中：

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
2. **Main 闭包求交**：实测 Main 闭包 = 175,185 模块，anyGeometry 的 24 文件 **24/24 全在闭包内**。
3. **性质**：全部为**显式参数**（`geoCl anyGeometry`、`movable_geometric … anyGeometry`），**零 instance 字段**（无 `[anyGeometry]`、无 `instance … anyGeometry`）。

### 结论

Main 依赖路径**确实走 anyGeometry**。但 `anyGeometry` 恒真（`fun _ _ _ => True`），作为几何条件参数是「最弱/平凡」条件，合法且保守，本身不构成「偷换」的直接证据。

**未闭合的下一步**：逐点比对 `geoOf Q`（真几何）与 `anyGeometry` 在 Main 链上是否被替换——需更深一层的证明追踪。

## 信任链条四行表

| 层 | 本项目的位置 | 验证方式 |
| :-- | :-- | :-- |
| 命题 | 证明 Mathlib 的 `RiemannHypothesis`（等价经典 RH） | 类型检查等价（方案 A） |
| 公理 | 仅依赖 Mathlib 3 条公理：propext / Classical.choice / Quot.sound | `#print axioms` |
| 内核 | Lean 4 内核 type checker 逐项检查 | 编译 0 error |
| TCB | Lean 4 内核本身的可信基 | 不在本项目范围 |
