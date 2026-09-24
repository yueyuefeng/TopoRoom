# 自由绘制

新建户型 → **自由绘制** → blank canvas → finger/cursor walls → **完成** → existing 2D / 3D.

| File | Screen |
|------|--------|
| [01_new_plan.png](./01_new_plan.png) | 新建户型 with 自由绘制 (no toast) |
| [02_blank_canvas.png](./02_blank_canvas.png) | Empty draw mode — header (返回 / 标题 / 完成) at the **top** |
| [03_rectangle.png](./03_rectangle.png) | Closed 4000×3000 mm rectangle |
| [04_edit_2d.png](./04_edit_2d.png) | 2D editor — four-icon view pill at the **bottom** |
| [05_edit_3d.png](./05_edit_3d.png) | 3D editor — same compass pill at the **bottom** |

Walls are SceneIR commands (`add_wall` / `move_wall` / `delete_wall` / `resize_wall`) via Session. Snap to axis and nearby endpoints. Length labels open the numeric sheet.

## Debug APK 0.1.8 (`versionCode` 9)

**每次构建升版本；签名固定.** Same debug cert as 0.1.0–0.1.7. Install over the previous build.

0.1.8 moves the 2D/3D four-icon view-mode pill (▦ ▣ 🚶 ⛶) to a **bottom compass**. 自由绘制 header stays at the top.

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.8** (`versionCode` 9) arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `0f93f37ad665fecdb547c638c35695c7a50624566413f9ed121d426ef166dc44` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/oraxhg.apk |
| Mirror | https://gofile.io/d/Ax6iAJGg |
