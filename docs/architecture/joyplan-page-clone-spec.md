# JoyPlan 逐屏克隆规格（TopoRoom 必须对齐）

> **目标**：按用户参考视频 **原样抄页面**，不是“功能近似”。  
> **一手证据**：2026-09-18 参考视频逐帧拆解（watchVideo）。  
> **辅证**：用户 3D 静帧（顶/右/底三区）— 与视频 3D 屏有差异时 **以视频流程为主**，静帧用于补强右栏/摇杆密度。  
> **日期**：2026-09-18

## 硬约束（相对当前拓间原型必须撕掉的）

1. **禁止**通栏 Header / Footer / 大 FAB 作为主导航。  
2. 所有主控件必须是 **悬浮 island**（白胶囊 / 独立白圆 + 阴影），画布四边透出。  
3. 选中操作在 **物体旁上下文 pill**，不进顶栏菜单。  
4. 素材库是 **底部 sheet 长按拖出**，不是点选再点墙。  
5. 2D↔3D 用 **顶栏胶囊切换** + 2D 底栏绿色 3D 入口 / 3D 左下绿色回 2D。

---

## Screen map（实现清单）

| # | 屏 | P0 |
|---|---|---|
| S1 | 系统相机/相册导入 | ✓（系统） |
| S2 | Scale Calibration | ✓ |
| S3 | 2D Base Edit | ✓ |
| S4 | 2D Bottom Library drag | ✓ |
| S5 | 3D Walkthrough / edit | ✓ |
| S6 | Ruler display sheet | ✓ |
| S7 | 3D Dimension HUD | ✓ |
| S8 | Elevation Index（深色） | P1 stub OK |

---

## S2 — Scale Calibration（00:03–00:07）

**Canvas**：全屏户型照片；房间可粉红淡染。  
**TOP**：左 `<` 圆；中胶囊 `Scale setting` + `i`；右 `1F` 圆角块。  
**Overlay**：蓝比例尺线 + 两端圆把手；拖时 **loupe**（白边圆镜+十字+阴影）在指上方。  
**BOTTOM sheet（深色磨砂）**：标题 `Adjust floor plan`（粉上箭头）；文案 `Place the scale on a known measurement` / `Please enter the length of the scale`；左 `Exit` 灰，右 `OK` 粉；数字输入。  
**中文宿主文案**：可用「比例设置 / 调整户型 / 退出 / 确定」，布局必须同构。

---

## S3 — 2D Base Edit（00:07–00:09）

**Canvas**：白底；黑粗墙；房间浅灰/浅橙填色；房间名+面积。  
**TOP**：左 `<`；**中胶囊仅 2 段**：左 2D 网格（选中黑）、右 3D 方块（灰）；右 `1F`。  
**TOP-LEFT readout pill**：`L … ∠ …`（选墙时）。  
**Contextual pill**（贴选中物）：设置 / 复制 / 删除（等）。  
**BOTTOM dock**：白胶囊三图标——左 **绿 3D 小屋/播放**、中 指南针/定位、右 保存。  
**选中**：房间浅橙填充。

---

## S4 — Bottom Library（00:09–00:11）

**Sheet**：白底盖住下方约 1/3；Tab：`Favorite` `Door` `Window` `Beam tube` `Electric…`；网格门窗项。  
**Coach**：贴底蓝胶囊 `Long press widgets to add to floor plan`。  
**Drag**：长按图标拖上画布；近墙吸附；拖时出现到墙角的红/黑动态尺寸线。  
**松手**：切洞；出现上下文 pill。  
**TOP-LEFT**：可变为 `L 900 W 200 H 2100`。

---

## S5 — 3D Walkthrough（00:12–00:20）

**Canvas**：白/灰墙 + 地面纹理。  
**TOP**：同 S3 但 3D 段选中。  
**RIGHT rail**：**分离的白圆按钮竖排**（非连体条）— 齿轮 / 眼睛 / 盒 / 尺规 / 笔 / 曲线…  
**BOTTOM-LEFT**：绿色圆钮（2D 平面图标）回 2D。  
**BOTTOM-RIGHT**：白胶囊 Undo/Redo。  
**Minimap**：左上深色磨砂方块 + 白点 + **FOV 扇形**随相机动。  
**辅证静帧可加**：摇杆、更多右栏图标、日光钮——若加入不得破坏上述视频结构。

---

## S6 — Ruler display（00:20–00:21）

白底 sheet：`Ruler display`；`Cancel` 灰 / `OK` 紫；项：`Column` `Plumbing` `Select All` `Dimensions` `Thickness information`；勾选紫对勾。

---

## S7 — 3D Dimension HUD（00:21–00:29）

尺寸线与数字 **粉/红** 直接画在 3D 空间（无底板），贴门洞/层高/墙长。

---

## S8 — Elevation Index（00:29–00:34）P1

深色画布；顶栏深色 pill（存/撤/重 | All/Elevation）；底栏 Annotation/Draw；过渡提示 `Elevation Index`；多立面卡片网格。

---

## 实现顺序（逐笔提交）

1. `docs: JoyPlan page-clone screen map from reference video`  
2. `feat(ux): rewrite scale calibration screen to match S2 islands`  
3. `feat(ux): rewrite 2D chrome to S3 top toggle + bottom 3-icon pill`  
4. `feat(ux): 2D library sheet + blue long-press coach + drag dims`  
5. `feat(ux): contextual action pill adjacent to selection`  
6. `feat(ux): rewrite 3D chrome — detached right circles + minimap FOV + green back-to-2D`  
7. `feat(ux): ruler display sheet S6 + in-world dimension HUD S7`  
8. `feat(ux): stub elevation index entry P1`  
9. Screenshots + Debug APK

## 验收剧本

相册选图 → S2 拖把手见 loupe → OK → S3 见顶栏 2D/3D 胶囊与底栏三图标 → 开库长按拖门 → 吸附有尺寸线 → 顶栏切 3D → 见右栏圆钮与小地图 FOV → 尺规 sheet → 空间粉红尺寸 → （可选）Elevation stub。
