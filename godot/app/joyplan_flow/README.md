# JoyPlan interaction flow

Product UI lives here. `res://app/main.tscn` boots `home.tscn`.

| Scene | Screen | Notes |
|---|---|---|
| `home.tscn` | S1 | 拓间 home: 示例户型 / 相册导入 / 拍照 |
| `scale_calibrate.tscn` | S2 | Loupe + dark 调整户型 sheet |
| `edit_2d.tscn` | S3+S4 | 2D\|3D capsule, library sheet, contextual pill, 3-icon dock |
| `edit_3d.tscn` | S5–S7 | Detached right circles, minimap FOV, green 2D, pink dims |
| `elevation_index.tscn` | S8 | Dark stub (P1) |

Legacy workbench: `res://app/_legacy/` (not on the run path).
SceneIR millimetres still only move through `Session` → `TopoRoomHost`.
