# 读解：外部佐证 — Nielsen 消融实验与无效性论证

> 归档日期：2026-11-25 · 外部佐证 · 第三方复现记录
> 来源仓库：`makyoagi/riemann-hypothesis-lean`（Jenny Lorraine Nielsen）
> 关联本文档：[读解_anyGeometry依赖路径与信任链条.md](读解_anyGeometry依赖路径与信任链条.md)（0.7 / 0.8 结论）

## 0. 这是什么

`makyoagi/riemann-hypothesis-lean` 不是又一个镜像，而是**直接针对 `anyGeometry` 问题的实测仓库**。作者 Jenny Lorraine Nielsen（ORCID `0000-0003-3841-2257`），配套预印本论文：

> Nielsen, *The Invalidity of Alpöge's Proposed Proof of the Riemann Hypothesis*, PhilArchive / PhilPapers，2026-11-21。摘要关键词：**"Vacuously true geometric and lattice witnesses in the Lean formalization"**（Lean 形式化中的「空真几何/格见证」）。

三支分支：

| 分支 | 内容 |
| :-- | :-- |
| `main` | 原始源码（与 `CocoSgt/riemann-hypothesis-lean` 镜像同源，钉同一条上游 SHA） |
| `anygeometry-ablation` | **删掉 `anyGeometry` 与 `OAt.geo` 字段**，重编译 |
| `production-geometry` | 用真实几何（截面映射满足 `Reads`）**替换** anyGeometry |

证据在 `checks/geometry/verification.txt` 与 `checks/geometry/README.md`。

## 1. Ablation 收据（实测，非声称）

来源：`a7c4411d36ecfd01570551116fb11251c27a2322/checks/geometry/verification.txt`。

| 项 | 值 |
| :-- | :-- |
| 镜像 commit | `7cbf7a0c32fca1badf05931879a37c3f8a2b03b4`（= 本项目 `main` 的 SHA） |
| Mathlib | `0df444a360eaa60ab8c11dca51a86af692955474` |
| Lean | `4.33.1` |
| 编译 | `FINAL 5691/5691; failed []`（5,691 受影响模块全过） |
| 删后 RH 定理 | `riemannHypothesis : RiemannHypothesis` 不变 |
| 公理 | `[propext, Classical.choice, Quot.sound]` 不变 |
| 声明比对 | `Matched names, universes, types and bodies for 1451 declarations in 192 original modules.` |
| 删除确认 | `Absent from the Main environment: GlobalTheory.Mem.Top.Bl.anyGeometry` 与 `…OAt.geo` |
| 内核重放 | `Kernel replay of modified Main … replaying Main` 通过 |

负控制（空槽依赖控制）：`controls/rh-divex-prov-ablation-control.lean` 预期 exit 1，报错

```
riemannHypothesis reaches the empty-slot lemma GlobalTheory.Mem.Top.DivRec.divEx_prov
```

即 ablation 版里 RH 会触达「空槽引理」`divEx_prov`，证明原证明的几何槽确实被走到、且被空置。

> 命名说明：`GlobalTheory.Mem.Top.Bl.anyGeometry` 即本项目追踪的 `OverIx.lean` 中的 `anyGeometry`（Lean 命名空间 ≠ 文件路径）；`OAt.geo` 即 `OAt` 记录的 `geo` 字段。两者正是 0.7/0.8 追踪的对象。

## 2. 对 0.8 结论的修正

本项目 0.8 的定性：

> `anyGeometry` 在证明链上（0.7，文本层）；真实几何 `IsGeoOf` 从不进链；「几何侧被抽空」；定性为「实质性偷懒」；(A) 无害抽象 vs (B) 偷懒缺口 **需数学专家裁决**。

Nielsen 的 ablation 把「文本层 vs 语义层」的缝隙补上：

- 我们说的「在证明链上」是**文本/定义层**的（`oAt_any` 用 `trivial` 填 `geo`、`divEx_geoCl` 读 `o.geo`）——词面上 anyGeometry 确实被引用。
- Nielsen 的「可删除」是**语义层**的——`geo` 字段值恒真、其结果从未约束最终定理，所以连字段带 `anyGeometry` 一起删掉，证明照过、公理不变。

两者不矛盾，但 Nielsen 的表述比 0.8 **更准、更狠**：

> 不是「真实几何被换成恒真 anyGeometry」，而是「几何字段从头到尾**可整体删除、纯死参数**」。

这实质排除了 0.8 悬置的 (A)「正确抽象」——一个可整体删除的字段不可能是证明的必要抽象。

## 3. Production-geometry 反例（决定性）

Nielsen 不止停在「几何是空的」，而是**亲手把真实几何填回去**，再问「真实几何下证明还成立吗」。production 参数改为：

```lean
OX (some (geoCl (geoOf (fun D => IsKitOf (stages D)))))
```

截面映射须满足 `Reads`；构造函数须在原始行证 `geoOf`，经 `GeoCl.base` / `GeoCl.step` 传递，最终路径经 `memberE_closing_alt_alt` → `divEx_geometry` → `closed_divEx` → `production_geometry` → `production_reads`。

结果分两层：

**（a）RH 定理本身仍通过**：4,330 受影响模块重建，`riemannHypothesis` 照旧 3 公理。故内核层面「RH 命题类型正确」在三种配置（原版 / 删字段 / 真几何）下都成立。

**（b）高度比较这一环破了**（「无效」主张的真正依据）：

- **自我修正**：论文 §8 曾称「高度比较靠 reflexivity 成立」，仓库里明确写**该说法是错的**——`setDiv` 存 `hExpl6` 的等式确实 `rfl`，但上界是**独立的算术估计**，非 reflexivity。
- **反例 1（size 常数）**：增大 size 常数 `k`，赋值高度 `hExpl6` 仿射上升（正斜率），每字等高差保留、`h_eq` 仍 `rfl`，但固定误差容限下**上界在选定字失效**（对 `prm0/prm1/prmA` 三 production 参数均成立）。
- **反例 2（线丛选择）**：level-prime 扭转在每个固定分量上至少一字错过赋值高度；超平面测试中两字同权→选同一 modeled tensor 幂，但赋值公式给它们不同高度。
- **未决障碍**：「最后一行的每个分量边界为空」「`hExpl6` 与独立算术高度的等同**仍未闭合**」——最后一行的截面度量公式仍需证明截面在每个内点生成线丛并算出算术自交。

**结论**：原证明之所以「成立」，恰恰是因为几何槽被 `anyGeometry` 恒真**空置**，真实几何高度机制从未被真正调用；一旦真填几何，高度估计站不住。

## 4. Nielsen 论文本体与反驳线索

- 论文：*The Invalidity of Alpöge's Proposed Proof of the Riemann Hypothesis*，PhilArchive `NIEIOT-2v1`，2026-11-21。核心论证即「空真几何/格见证」：§2 追 `geoCl anyGeometry`，§13 与附录 A 论证 RH 路线依赖其识别的空真输入。
- PDF 与正文被 Anubis/Cloudflare 反爬挡住（`WebFetch` 返回验证页），全文未取到，需浏览器或人工获取。
- **已有反驳**：Zijian Zeng（UCSI University）《*The Invalidity of 'The Invalidity of Alpöge's Proof of the Riemann Hypothesis'*》——Nielsen 的「无效」主张本身也在被质疑。

## 5. 定性与可信度

| 判断 | 定性 | 可信度 |
| :-- | :-- | :-- |
| 几何字段可整体删除（语义死参数） | 有收据（5691 模块 + 内核重放 + 声明比对） | 高（但单机运行，独立复现待定） |
| 真几何下高度估计失效 | 有反例（size 常数 / 线丛选择 / 最后一行边界） | 中（自述独立复现待定，且 §8 曾自误，分析在演进） |
| 「证明无效」总断言 | 依赖「几何高度环节是证明的必需桥梁」这一数学判断 | **未定**（已遭 Zeng 反驳，形式化内核无法自动闭合） |

**残余判断**：Nielsen 的 ablation + production 双实验，把我们 0.8 的「(A)/(B) 需专家裁决」推进为「(B) 倾向的强证据」——几何字段可删（排除正确抽象）+ 真几何下高度失效（真实几何环节站不住）。但「无效」是否成立，取决于数学上「真实几何高度」是否为 RH 证明的必需桥梁，这一层内核检查不到，且已出现反驳，**仍不能当作定论**，只能作为「定义层」验证的有力外部佐证。

## 6. 待办（可选）

- 取 Nielsen PDF 全文（§2 / §13 / 附录 A），核对消融论证细节。
- 取 Zeng 反驳，看其是否推翻「几何高度必需」这一前提。
- 独立复现 ablation（同 SHA `7cbf7a0c…`，可复用 IP47/IP121 Lean 工具链；5,691 模块规模大，需单独评估）。
