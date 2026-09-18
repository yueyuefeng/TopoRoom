# JoyPlan interaction flow

Product UI lives here. `res://app/main.tscn` boots `home.tscn`.

Click path: **Home → 我的项目 → 工程项目 → 新建项目 → 新建户型 → 导入户型图 → 选择户型图 → 1/2 比例 → 2/2 生成空间 → 2D**.

| Scene | Screen | Notes |
|---|---|---|
| `home.tscn` | Home | Hero interior, 2×2 cards, dark capsule nav |
| `projects.tscn` | 工程项目 | Orange 新建项目 + quota banner |
| `new_plan.tscn` | 新建户型 | AR/自由绘制 toast; 导入户型图 works |
| `pick_source_modal.gd` | 选择户型图 | 相册 / 拍照 / 使用示例户型 |
| `scale_calibrate.tscn` | 1/2 临摹图比例 | Blue handles + mm keypad |
| `generate_space.tscn` | 2/2 生成空间 | Preview then 确定 → 2D |
| `edit_2d.tscn` | S3+S4 | 4-mode capsule, + menu 导入户型图 |
| `edit_3d.tscn` | S5–S7 | Detached right circles, minimap FOV |
| `elevation_index.tscn` | S8 | Dark stub (P1) |

Legacy workbench: `res://app/_legacy/` (not on the run path).
SceneIR millimetres still only move through `Session` → `TopoRoomHost`.
