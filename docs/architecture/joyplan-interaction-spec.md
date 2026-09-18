# JoyPlan 式量房交互规格（拓间 TopoRoom 对标复刻）

> **文档性质**：交互复刻规格（Interaction Spec），供拓间 Godot 宿主按阶段实现。  
> **整理日期**：2026-09-18  
> **信息原则**：每条交互标注证据来源；未在视频/公开文档中确认的标「待验证」，禁止当作已观测事实。  
> **产品别名**：JoyPlan / 乐规划 / 樂規畫；大陆同源能力常称「知户型」（`com.zbj.zhouse`）。国际包名 `com.zbj.joyplan`。

---

## 0. 证据来源

| ID | 来源 | 覆盖重点 | 置信度 |
|---|---|---|---|
| V1 | 用户提供参考视频（2026-09-18，英文 UI） | 拍照→相册→比例尺+放大镜→自动描墙成房→底部库长按拖门窗→上下文工具条→FAB 2D↔3D→3D 放置→尺寸图层→Elevation Index | **高（一手）** |
| P1 | `/workspace/analysis/joyplan-prd.md`（2026-09-10，商店/官网/博客逆向） | 功能全集、手势总表、2D/3D/漫游/立面、管综长按吸附、属性面板 | 高 |
| W1 | https://joyplan.com.tw/learning/ 樂規畫 6.0 课程目录 | 临摹方案、CAD 调比例、墙高、属性、硬软装、立面/鸟瞰等教学条目 | 高 |
| S1 | Google Play / App Store JoyPlan 文案 | 图像生成 3D、LiDAR、导出、渲染卖点 | 中高 |
| Z1 | 知户型 / zbjsaas 产品页与帮助中心 | 软硬装三层、手柄式漫游、测距量房口径 | 中（同源推断） |
| T1 | TikTok / 抖音短视频检索（进行中） | 短演示节奏、口播卖点；**URL 以实搜为准，未找到不编造** | 待补 |

---

## 1. 产品交互目标（对标一句话）

用户在手机上完成：**导入/临摹户型 → 校准尺度 → 得到可编辑的封闭墙体与房间 → 用素材库把门窗梁柱「拖到墙上」→ 在 2D/3D 间无缝切换核对尺寸 →（可选）立面/CAD/漫游谈单**。

拓间 P0 对标焦点：**照片户型导入链路 + 2D 编辑主战场 + FAB 进 3D 编辑**；渲染/全景/报价/多层别墅为 P1+。

---

## 2. 端到端主路径（推荐复刻顺序）

```mermaid
flowchart LR
  A[相机/相册选图] --> B[比例尺校准]
  B --> C[自动识别/描摹]
  C --> D[2D 审图与拆改]
  D --> E[底部库拖门窗]
  E --> F[点选上下文编辑]
  F --> G[FAB 进入 3D]
  G --> H[3D 放置与尺寸层]
  H --> I[可选: 立面/CAD/漫游]
```

### 2.1 逐步交互剧本（以 V1 为主干，P1/W1 补全）

#### Step A — 采集底图
| 项 | 规格 |
|---|---|
| 入口 | 「拍户型图」/ 导入；系统相机或相册 |
| 权限 | iOS/Android 相册私密访问弹层（V1）；相机权限 |
| 成功态 | 进入比例尺屏，底图全屏半透明可平移缩放 |
| 失败态 | Snackbar：权限拒绝 / 图片损坏 |
| 拓间现状 | 已有相机/相册插件入口 |
| P0 要求 | 选图后**必须**进入校准，不可直接跳识别结果 |

#### Step B — 比例尺校准（Scale setting）
| 项 | 规格 |
|---|---|
| UI | 双圆形把手 + 虚线量尺叠在底图已知边上；标题「比例设置 / Adjust floor plan」 |
| 放大镜 Loupe | 拖把手时手指上方出现局部放大圆镜，便于贴线（V1） |
| 数值 | 底部表单输入真实长度（mm）；默认示例 900 |
| 确认 | 「确定 / OK」写入 `mm_per_px`，关闭表单 |
| 手势 | 单指拖把手；双指缩放/平移底图；拖动时 loupe 跟随 |
| 证据 | V1 强；W1「CAD圖調整比例」「臨摹方案」；P1 F 临摹 |
| 拓间现状 | PR #19 已有双把手 + mm 输入；loupe 可加强 |
| P0 完成定义 | 校准后识别尺度与金样边长误差可控；可重开校准 |

#### Step C — 自动描墙成房
| 项 | 规格 |
|---|---|
| 视觉 | 淡化底图；墙段叠加；房间填色；房间名 + 面积标签（V1 英文 Living Room + sq ft） |
| 墙语义 | 承重/剪力墙与砌体视觉区分（V1 斜线 hatch；P1 墙属性） |
| 开口 | 自动门窗洞或稍后由库补齐 |
| 拓扑 | **外轮廓必须闭合**（拓间硬约束，来自用户金样反馈） |
| 拓间现状 | FloorPlanRasterAnalyzer + 封口 TDD；房间填色/面积已部分落地 |
| P0 完成定义 | 金样外轮廓闭合；房间 polygon 可填色；承重 hatch 可见 |

#### Step D — 2D 审图与拆改
| 项 | 规格 |
|---|---|
| 选择 | 点选墙段/门窗高亮 |
| 拆改 | 拆非承重；承重需强确认（拓间已有 force confirm 思路） |
| 手动绘制 | 底栏「自动识别 / 手动绘制」双 Tab（用户识图 UI 截图）；右栏修改/规范/清除/撤销 |
| 证据 | V1 弱（未演示拆墙）；P1 墙打断/属性；用户截图识图 UI |
| P0 | 点选 + 拆砌体 + 承重确认；手动画墙可 P0.5 |

#### Step E — 底部素材库长按拖放
| 项 | 规格 |
|---|---|
| 容器 | 上拉 Bottom Sheet；横向/网格分类 Tab：收藏、门、窗、梁管、电气…（V1） |
| 教练提示 | Coach mark：「长按控件拖到平面图」 |
| 手势 | **长按**取出幽灵图标 → 拖到画布 → 近墙高亮吸附 → 松手切洞 `add_opening` |
| 吸附 | 对齐墙中线/墙面；自动旋转贴墙 |
| 3D 同构 | 3D 中同一库可拖到竖直墙面（V1） |
| 证据 | V1 强；P1 管综「长按拖拽+高亮吸附」同范式 |
| 拓间现状 | PR #19 门/窗库 + 长按拖；需核对吸附手感与 Tab 完整度 |
| P0 | 门/窗/垭口三类；吸附成功有触觉或高亮反馈 |

#### Step F — 点选与上下文工具条
| 项 | 规格 |
|---|---|
| 选中反馈 | 对象高亮；浮在物体上方的迷你工具条 |
| 工具条动作 | 翻转 / 旋转 / 复制 / 删除（V1）；墙可改承重/砌体 |
| 顶栏尺寸 | 显示 L / W / H；可点数字改（P1：点尺寸数字精确编辑） |
| 证据 | V1 工具条；P1 点尺寸数字 |
| 拓间现状 | 上下文工具条 + L/W/H 读出已提交；数字编辑可加强 |

#### Step G — FAB 2D ↔ 3D
| 项 | 规格 |
|---|---|
| 控件 | 主色圆形 FAB，固定在底部安全区上方（避开 Sheet） |
| 动效 | 2D 线框上挤成 3D（V1 有挤出感）；可降级为硬切 |
| 状态 | 2D 显示「3D」；3D 显示「2D」 |
| 证据 | V1 |
| 拓间现状 | 已有 FAB；动效可选 |

#### Step H — 3D 编辑与尺寸图层
| 项 | 规格 |
|---|---|
| 导航 | 单指旋转/环视，双指缩放；（桌面）右键旋转滚轮缩放（拓间现有） |
| 编辑 | 点墙/洞 → 手柄拖动 → 松手命令写回 SceneIR |
| 尺寸层 | 右侧工具打开「Ruler display」多选：柱/管/尺寸/墙厚…（V1） |
| 灯光 | 白天/暖光分段控件（拓间已有） |

#### Step I — 立面 / CAD / 漫游（P1）
| 项 | 规格 |
|---|---|
| Elevation Index | 深色网格多立面缩略（V1 片尾） |
| 漫游 | 第一人称 + 手柄式（Z1/P1） |
| 导出 | CAD/PDF/glTF（P1） |

---

## 3. 屏幕与组件清单

### 3.1 屏幕

| 屏 | 目的 | P0 |
|---|---|---|
| Home / 方案列表 | 新建/打开 | 简版 |
| 媒体选择 | 相机/相册 | ✓ |
| 比例尺校准 | 设 mm_per_px | ✓ |
| 2D 工作台 | 审图/拆改/库/选中 | ✓ |
| 3D 编辑 | 体量核对与手柄编辑 | ✓ |
| 3D 漫游 | 谈单只读 | P1 |
| 立面索引 | 出图预览 | P1 |
| 设置/图层 | 尺寸层开关 | ✓ 简版 |

### 3.2 可复用组件

| 组件 | 行为要点 |
|---|---|
| BottomSheetLibrary | Tab + 网格；长按开始拖 |
| DragGhost | 半透明跟随指尖 |
| WallSnapTarget | 近距高亮 + 吸附角 |
| ContextualToolbar | 选中锚点上方 |
| DimensionHUD | 顶栏 L/W/H |
| ScaleHandles + Loupe | 校准专用 |
| PrimaryFAB | 视图切换 |
| CoachMark | 一次性引导 |
| Snackbar | 轻反馈 |
| HatchFill | 承重斜线 |

---

## 4. 手势与反馈表

| 手势 | 2D | 3D | 备注 |
|---|---|---|---|
| 单指拖 | 平移画布 / 拖把手 / 拖素材 | 环视或拖手柄 | 冲突时：选中优先 |
| 长按 | 从库取出 | 同左 | ≥350ms |
| 双指捏合 | 缩放 | 缩放 | |
| 轻点 | 选中 | 选中 | |
| 双击尺寸 | 弹出数字键盘 | 同 | P1 强化 |
| 松手 | 提交命令写 SceneIR | 同 | 预览≠提交 |

触觉（若系统允许）：吸附成功短振；承重拆墙警告重振。

---

## 5. 状态机（2D 工作台）

```
Idle
  ├ tap object → Selected
  ├ long-press library → DraggingAsset
  ├ pinch/pan → Navigating (transient)
  └ FAB → leave to 3D

Selected
  ├ toolbar action → mutate → Idle/Selected
  ├ tap empty → Idle
  └ drag handle → Previewing → commit on release

DraggingAsset
  ├ near wall → SnapPreview
  └ release → AddOpening command → Selected|Idle
```

---

## 6. 与拓间差距矩阵（2026-09-18）

| 能力 | JoyPlan(V1/P1) | 拓间现状 | 优先级 |
|---|---|---|---|
| 选图导入 | ✓ | ✓ | — |
| 比例尺+Loupe | ✓ | 校准有，Loupe 弱 | P0 打磨 |
| 外轮廓闭合识别 | 产品隐含 | TDD 已合（#18） | 回归 |
| 房间填色+面积 | ✓ | ✓ 基础 | 打磨标签样式 |
| 底部库长按吸附 | ✓ 多 Tab | 门窗垭口 | P0 手感 |
| 上下文工具条 | 翻/转/复/删 | 有 | 补齐动作 |
| 点数字改尺寸 | ✓ | 只读偏多 | P0 |
| FAB 2D↔3D | ✓ 挤出感 | ✓ 硬切可接受 | P0.5 动效 |
| 3D 拖库上墙 | ✓ | 部分 | P0 |
| 尺寸图层多选 | ✓ | 开关级 | P0 |
| 承重 hatch | ✓ | ✓ | — |
| 拆墙确认 | 产品有可移动非承重 | 有 | 对齐文案 |
| 手动画墙游标 | ✓ | 弱 | P0.5 |
| 立面索引 | ✓ V1 | ✗ | P1 |
| 漫游手柄 | ✓ | 只读漫游有 | P1 |
| 蓝牙测距写入边长 | ✓ | Fake/Replay | 硬件轨 |
| 软装三层/管综库 | ✓ | ✗ | P1+ |
| 渲染/全景 | ✓ | ✗ | P1+ |

---

## 7. 实施计划（按功能点逐笔提交）

### Phase A — 交互规格入库
1. `docs: JoyPlan interaction spec for TopoRoom host` — 本文档进仓库

### Phase B — 校准与识别闭环打磨
2. `feat(ux): scale loupe while dragging calibration handles`
3. `fix(vision): regression — gold sample closed envelope after calibrate`
4. `feat(ux): room label typography + area unit m²`

### Phase C — 库与编辑手感（对标 V1）
5. `feat(ux): library tabs Favorite/Door/Window + coach mark`
6. `feat(ux): wall snap highlight + haptics on opening drop`
7. `feat(ux): contextual toolbar flip/rotate/duplicate/delete`
8. `feat(ux): tap L/W/H to edit via numeric sheet`

### Phase D — 视图与 3D 同构
9. `feat(ux): FAB 2D↔3D with simple extrude tween`
10. `feat(ux): 3D library long-press place on wall`
11. `feat(ux): ruler display multi-toggle sheet`

### Phase E — 拆改与引导
12. `feat(ux): demolish masonry + force-confirm shear`
13. `feat(ux): first-run coach marks sequence`

### Phase F — P1（本迭代不阻塞）
14. 立面索引、漫游摇杆、CAD 导出、软装库…

**验收剧本（人工）**  
选相册金样 → 校准已知边 → 审图外轮廓闭合 → 长按拖一门一窗 → 点选看工具条与 LWH → FAB 进 3D → 开尺寸层 → 回到 2D。

---

## 8. TikTok / 短视频附录（待补）

检索关键词建议：`JoyPlan floor plan`、`JoyPlan measure`、`乐规划 量房`、`知户型 户型图`、`@joyplaner`。  
规则：只记录实际打开过的 URL；抓不到则写「本轮未获得可复现 TikTok 链，交互以 V1+P1+W1 为准」。

| URL | 标题/账号 | 观察到的交互要点 | 日期 |
|---|---|---|---|
| （用户截图，完整 URL 未提供） | TikTok `@joyplan.app` 0:18 / 0:35 | 3D 三区 chrome：顶栏返回+四模式+LWH+1F；右侧竖轨保存/设置/消息/图层/库/编辑/更多；底栏撤销重做+虚拟摇杆+灯光+绿色主按钮 | 2026-09-18 |

---

## 9. 变更记录

| 日期 | 变更 |
|---|---|
| 2026-09-18 | 初版：融合 V1 视频拆解 + joyplan-prd 第 3–4 章 + 樂規畫课程目录；给出拓间差距与分 commit 实施计划 |
| 2026-09-18 | 增补 §10 Chrome 三区布局（TikTok @joyplan.app 截图）；Godot 2D/3D 落地 frosted pills |

---

## 10. Chrome 三区布局（V1 3D 截图）

证据：用户 2026-09-18 提供的 JoyPlan 3D 工作台截图（TikTok `@joyplan.app`）。视频播放器控件忽略。样式：半透明磨砂圆/胶囊，画布最大化。

| 区 | 控件 | 拓间接线 |
|---|---|---|
| **顶栏** | 返回圆钮 | 2D `_back` / 3D 回首页 |
| | 四模式：平面 / 立体（选中） / 漫游 / 展开 | `plan`→`photo_stub`；`cube`→`edit_3d`；`roam`→`roam.tscn`；`expand` 收起轨与底栏 |
| | L / W / H 磨砂条 | 点数字 → `numeric_sheet` → 命令 |
| | `1F` 楼层芯片 | P0 一层；toast「多层 P1」 |
| **右侧竖轨** | 保存、设置、消息、图层（眼）、构件库（盒）、编辑（笔）、更多 | 保存=`auto_save`；眼=标尺 sheet；盒=门窗库；笔=上下文工具条；设置/消息 toast 稍后；更多=加载夹具（3D） |
| **底栏（仅 3D）** | 撤销 / 重做 | toast「命令历史 P1」 |
| | 大虚拟摇杆 | 环视：改 `_yaw` / `_pitch` |
| | 太阳 | `Lighting.toggle_preset` 白天/暖光 |
| | 绿色主按钮 | `export_deliverables` |

2D 工作台共用顶栏 + 右轨，**没有摇杆**。实现：`godot/app/ui/joyplan_chrome.gd`。

截图：`docs/screenshots/04-photo-review-kinds.png`（2D）、`docs/screenshots/07-edit-3d-day.png`（3D）。
