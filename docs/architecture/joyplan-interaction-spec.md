# JoyPlan 交互对标规格（TopoRoom Godot host）

- **Status**: Phase B–E implementation target (stacks on PR #19)
- **Depends**: [ADR-001](./ADR-001-godot-interaction-shell-host.md),
  [ADR-002](./ADR-002-godot-3d-command-synced-edit.md),
  [ADR-003](./ADR-003-floorplan-vision-no-ocr-p0.md),
  [ux-joyplan-interaction-mapping.md](./ux-joyplan-interaction-mapping.md)
- **Invariant**: C++ SceneIR / `FloorPlanDocument` is millimetre truth.
  Godot is InteractionShell + Visualization. Every structural write is
  `gesture → Session → TopoRoomHost → C API → SceneIR`.

This document is the host interaction spec for making TopoRoom *feel* closer
to JoyPlan V1 on the **photo floor-plan path**. It is not a reimplementation
of JoyPlan 6.0 (硬装 / 软装 / 全景 / 真机蓝牙测距仪 are out of scope).

---

## 1. Evidence sources

| ID | Source | What we take from it |
|----|--------|----------------------|
| **V1** | JoyPlan V1 量房录屏（内部对照，户型图标定 → 2D 构件库拖放 → 上下文工具条 → FAB 进 3D） | Dual-handle scale + loupe; long-press library drag; snap to wall; L/W/H tap-to-edit; flip/rotate/duplicate/delete; 2D↔3D FAB |
| **PRD** | TopoRoom P0 量房 PRD + FINAL architecture (SceneIR 0.2, StatusGate, I1/I8) | Commands not meshes; 承重拆除二次确认; 门洞/窗洞/垭口 required kinds |
| **Learn** | [joyplan.com.tw/learning](https://joyplan.com.tw/learning) 乐规划 6.0 课程目录 | 临摹方案、属性（房间命名/空间类型）、墙高编辑、面积清单、CAD 比例、硬装/软装/全景 — P1+ only except 墙高/面积 |
| **Tips** | [post64 测绘六步](https://joyplan.com.tw/post64/) | 点墙旁数据改长/厚/属性；平面拖构件；立面点选门窗调边距；面积清单；一键 CAD |
| **Map** | `ux-joyplan-interaction-mapping.md` (PR #19) | Calibrate → closed envelope → room fill → library drag → L/W/H readout → FAB already on host |

TikTok / 短视频拆解表见附录 A（本轮留空，后续补时间码）。

---

## 2. End-to-end main path

```
拍/选图
  → 标定（双手柄 + 拖动放大镜 + mm）
  → 自动描墙（闭合外轮廓 + 房间填色）
  → 2D 确认承重 / 拆改
  → 底栏长按拖门窗，吸附墙段
  → 选中后上下文工具条 + 点 L/W/H 数字底栏
  → FAB 2D ↔ 3D（短挤出过渡）
  → 3D 长按库放置 + 尺寸图层
  → P1：立面 / CAD / 漫游   ← 本轮不做完整 Elevation Index / CAD 暗色 / 软装 / 全景 / 真 BLE
```

**Success for this spec:** a reviewer on phone can complete the path above
without leaving SceneIR as truth, and the gestures match the V1 table in §4.

---

## 3. Screen / component inventory

| Screen | Godot | Role |
|--------|-------|------|
| 首页 | `main.gd` | 拍户型图 / 相册 / 引导量房 |
| 导入 | `photo_stub.gd` pick | 系统相机、相册、示例图 |
| 标定 | `scale_calibrate.gd` | 双手柄 A/B、loupe、mm 底栏 |
| 2D 确认承重 | `photo_stub.gd` review + `plan_canvas.gd` | 房间填色、点墙改 kind、库、FAB |
| 2D 拆改 | `photo_stub.gd` demolish | 砌体直接拆；承重二次确认 |
| 门窗库 | `opening_library.gd` | 收藏 / 门 / 窗 tabs；长按拖；轻点落到选中墙 |
| 上下文工具条 | `_ctx` on 2D & 3D | 翻转 / 旋转 / 复制 / 删除（门窗）；承重/隔墙或拆除（墙） |
| L/W/H | 顶栏 chips + `numeric_sheet.gd` | 点数字 → mm 底栏 → 命令 |
| 标尺开关 | `ruler_sheet.gd` | 墙长 / 面积 / 洞口 / 网格 / 3D 尺寸 多选 |
| FAB | `Studio.fab` | 2D↔3D；挤出 tween 或直接切场景 |
| 3D 编辑 | `edit_3d.gd` | 命令同步实体、手柄、灯光、3D 库放置、尺寸层 |
| 教练 | `coach_marks.gd` | 首次流程气泡序列 |
| 漫游 / 导出 | `roam.gd` / Session export | P0 只读 glb；P1 CAD |

Shared chrome: `theme/tokens.gd`, `theme/studio.gd`, `ui/snackbar.gd`,
`ui/haptics.gd`. Prefs: `user://joyplan_ux.cfg` via Session.

---

## 4. Gesture table

| Gesture | Where | Result | Command / truth |
|---------|-------|--------|-----------------|
| Tap A/B handle, drag | 标定 | Handle follows; **loupe** shows 3× crop + crosshair | View only until 确定 |
| Type mm, 确定 | 标定 | `mm_per_px = real_mm / pixel_len` | `import_photo_vision(uri, mm_per_px)` |
| 跳过 / 按墙厚估 | 标定 | Analyzer default scale | `import_photo_vision(uri, 0)` |
| Tap wall | 2D | Select; L/W/H; kind chips | View; `set_wall_kind` on chip |
| Tap opening | 2D/3D | Select; toolbar flip/rotate/dup/del | View until action |
| Long-press library chip, drag | 2D 底栏 | Ghost + **wall snap highlight**; haptic on snap & drop | `add_opening(kind, wall_id, offset_mm)` |
| Tap library chip | 2D/3D | Place on selected wall (centred) | `add_opening` |
| Long-press library, drop on 3D wall | 3D | Ray → host wall, project offset | `add_opening` |
| Tap L / W / H chip | 2D/3D | Numeric bottom sheet | Wall: `resize_wall` / `set_wall_thickness` / `set_wall_height`. Opening: `update_opening` (L=宽, H=高; W=墙厚只读或改宿主墙) |
| Flip | 选中门窗 | 沿墙镜像偏移 | `update_opening` offset' = length − offset − width |
| Rotate | 选中门窗 | 门扇开向取反（可视化 + 与镜像互补） | View overlay `opening_swing`; optional offset mirror if 180° |
| Duplicate | 选中门窗 | 同墙相邻再放一个 | `add_opening` at offset+width+gap |
| Delete | 选中门窗 | 移除洞口 | `delete_opening` |
| 整段拆除（砌体） | 拆改 | 立即拆除 | `demolish_wall(id, force=false)` |
| 整段拆除（承重） | 拆改 | 底栏强制确认 | `demolish_wall(id, force=true)` after sheet |
| FAB 3D / 2D | 2D↔3D | Short extrude tween then scene switch | Scene only; StatusGate unchanged |
| Tap 尺寸 / 标尺 | 2D/3D | Multi-toggle sheet | Visualization flags in prefs |
| First-run coach | 各关键屏 | Spotlight + 下一步 | Prefs `coach_seen` |

Pinch-zoom of the photo during calibration is best-effort (loupe is the
required magnifier). Real BLE laser and 工程相机 are out of scope.

---

## 5. State machine

```
pick ──capture/gallery/example──► calibrate
                                      │
                         skip / commit mm_per_px
                                      ▼
                                   review ◄──────────── demolish
                                      │                     ▲
                                      │ 先拆改               │ 返回确认承重
                                      ▼                     │
                                   review ──FAB 3D──► edit_3d ──FAB 2D──► review
                                      │
                                   进入 3D (dock CTA, same as FAB)
```

Substates on **review/demolish/edit_3d**:

- `idle` — no selection
- `wall_selected` — L/W/H of wall; kind or demolish toolbar
- `opening_selected` — L/W/H of opening; flip/rotate/dup/del
- `library_dragging` — ghost + snap candidate
- `numeric_editing` — bottom sheet open; commits one command
- `coach` — overlay; does not mutate SceneIR
- `confirm_shear` — demolish/split/punch of `shearWall` blocked until force

Illegal transitions: FAB must not bypass StatusGate; drop without snap
refuses (no floating opening); skip-calibrate is allowed (analyzer scale).

---

## 6. TopoRoom gap matrix (vs V1 / PR #19)

| Capability | V1 / Learn | After PR #19 | Phase | This spec |
|------------|------------|--------------|-------|-----------|
| Dual-handle scale + mm | V1 | Handles + mm sheet | A done | Keep |
| Loupe while dragging handles | V1 | Basic crop, easy to miss | **B** | Crosshair, 3×, follow finger |
| Auto-trace closed envelope | PRD | Raster + seal | A done | Keep |
| Room name + area | Learn 属性 / 面积 | Fill + `"%.1f m²"` 15px | **B** | Typography polish, m² unit |
| Library tabs 收藏/门/窗 | V1 | Single row 门/窗/垭口 | **C** | Tabs + favorites + one-shot coach |
| Snap highlight + haptics | V1 | Ghost on wall, no haptic | **C** | Highlight host wall; `vibrate_handheld` Android |
| Toolbar flip/rotate/dup/del | V1 | Opening: caption only | **C** | Complete actions → commands |
| Tap L/W/H → numeric sheet | V1 / post64 | Readout only | **C** | Bottom sheet → resize/thickness/height/update_opening |
| FAB 2D↔3D | V1 | Instant scene switch | **D** | Extrude tween or graceful fallback |
| 3D library long-press on wall | V1 立面点选 | 2D library only | **D** | Same library, ray to wall |
| Ruler multi-toggle | V1 尺寸层 | 2D always-on dims; 3D 尺寸 chip | **E** | Sheet: 墙长/面积/洞口/网格/3D |
| 砌体拆除 vs 承重确认 copy | PRD | Confirm sheet exists | **E** | Align copy: 砌体直接拆；承重「确认拆除承重墙」 |
| First-run coach sequence | V1 新手引导 | None | **E** | Calibrate → 点墙 → 拖库 → LWH → FAB → 3D 放置 |
| Elevation Index / CAD dark | Learn CAD | DXF export only | P1 | **Out of scope** |
| Soft furnish / 全景 / BLE laser | Learn 6.0 | Fake laser in 引导量房 | P1 | **Out of scope** |

---

## 7. Phased commit plan (one feature = one commit)

Do **not** squash. Each `feat(ux):` is reviewable on its own.

### Phase A — already on parent (PR #19 / `5db3c88`)

Calibrate handles + mm; room fill; library drag snap; L/W/H readout; FAB;
load-bearing hatch; mapping doc.

### Phase B — calibration / 2D polish

1. `feat(ux): scale loupe while dragging calibration handles`
2. `feat(ux): room label typography + area unit m² (polish)`

### Phase C — library, snap, selection, numbers

3. `feat(ux): library tabs Favorite/Door/Window + coach mark`
4. `feat(ux): wall snap highlight + haptics on opening drop`
5. `feat(ux): contextual toolbar flip/rotate/duplicate/delete`
6. `feat(ux): tap L/W/H to edit via numeric bottom sheet → commands`

### Phase D — 2D↔3D and 3D place

7. `feat(ux): FAB 2D↔3D with simple extrude tween (or graceful fallback)`
8. `feat(ux): 3D library long-press place on wall`

### Phase E — rulers, demolish copy, first-run

9. `feat(ux): ruler display multi-toggle sheet`
10. `feat(ux): demolish masonry + force-confirm shear (align copy)`
11. `feat(ux): first-run coach marks sequence`

### Docs

- This file (`docs/architecture/joyplan-interaction-spec.md`)
- Pointer from `ux-joyplan-interaction-mapping.md`
- Screenshot README rows when captures exist

Core TDD (lands with the L/W/H commit): `Wall::with_thickness`,
`FloorPlanDocument::set_wall_thickness`, C API + GDExtension bind,
`EditingWorkflows` tests for thickness / flip offset / duplicate sibling.

---

## 8. Copy (Chinese, host)

| Slot | Copy |
|------|------|
| 标定 hint | 把两个点拖到一条已知边上，输入真实长度（毫米）。拖动时放大镜帮你对准。 |
| 库 caption | 长按拖到墙上，或点选墙后轻点 |
| 库 tabs | 收藏 / 门 / 窗 |
| 库 coach | 长按门或窗，拖到墙段上松手 |
| Snap miss | 拖到墙上再松手。 |
| L/W/H idle | 点选墙或门窗，看长宽高 |
| Numeric title (wall) | 墙长 / 墙厚 / 墙高 |
| Numeric title (opening) | 洞口宽 / 墙厚 / 洞口高 |
| Numeric unit | mm |
| Flip / 旋转 / 复制 / 删除 | 翻转 / 旋转 / 复制 / 删除 |
| 砌体拆除 snack | 已拆除隔墙 |
| 承重确认 title | 确认拆除承重墙 |
| 承重确认 body | 这面墙标成了承重墙。拆除会改写方案，需要你再点一次确认。 |
| 承重确认 CTA | 确认拆除 |
| 承重取消 | 先不拆 |
| FAB | `3D` / `2D` |
| Coach skip | 跳过引导 |

---

## 9. Files to touch (implementation)

| File | Change |
|------|--------|
| `godot/app/scale_calibrate.gd` | Loupe crosshair, follow handle |
| `godot/app/plan_canvas.gd` | Label type, m², snap highlight, ruler flags, door swing tick |
| `godot/app/opening_library.gd` | Tabs 收藏/门/窗, coach bubble |
| `godot/app/photo_stub.gd` | Toolbar, L/W/H chips, demolish copy, FAB tween hook, coach |
| `godot/app/edit_3d.gd` | 3D library, L/W/H sheet, camera tween, ruler |
| `godot/app/session.gd` | `resize_wall`, `set_wall_thickness`, `delete_opening`, flip/dup, prefs, haptic |
| `godot/app/ui/numeric_sheet.gd` | mm bottom sheet |
| `godot/app/ui/coach_marks.gd` | First-run sequence |
| `godot/app/ui/haptics.gd` | Android `Input.vibrate_handheld` best-effort |
| `godot/app/ui/ruler_sheet.gd` | Multi-toggle |
| `godot/export_presets.cfg` | `VIBRATE` |
| `core/…` | `set_wall_thickness` + tests |
| `godot/scripts/check_joyplan_interaction.sh` | String/command invariants |

---

## Appendix A — TikTok / 短视频拆解（空表）

Fill later with public short-form clips. Do not block Phase B–E on this.

| Clip | URL | Timecode | Gesture / UI | Maps to TopoRoom | Notes |
|------|-----|----------|--------------|------------------|-------|
| | | | | | |

---

## Appendix B — Command mapping (quick)

| UX | Session | C API |
|----|---------|-------|
| 标定提交 | `import_photo_vision` | `toporoom_vision_import_image_ex` |
| 改承重/隔墙 | `set_wall_kind` | `toporoom_document_set_wall_kind` |
| 放门窗 | `add_opening` | `toporoom_document_add_opening` |
| 改洞口尺寸/翻转偏移 | `update_opening_geom` | `toporoom_document_update_opening` |
| 删除洞口 | `delete_opening` | `toporoom_document_delete_opening` |
| 改墙长 | `resize_wall` | `toporoom_document_resize_wall` |
| 改墙厚 | `set_wall_thickness` | `toporoom_document_set_wall_thickness` |
| 改墙高 | `set_wall_height_mm` | `toporoom_document_set_wall_height` |
| 拆砌体 | `demolish_wall(id, false)` | `toporoom_document_demolish_wall` force=0 |
| 拆承重 | `demolish_wall(id, true)` | force=1 after confirm |
