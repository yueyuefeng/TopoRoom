# 自由绘制

新建户型 → **自由绘制** → blank canvas → finger/cursor walls → **完成** → existing 2D / 3D.

| File | Screen |
|------|--------|
| [01_new_plan.png](./01_new_plan.png) | 新建户型 with 自由绘制 (no toast) |
| [02_blank_canvas.png](./02_blank_canvas.png) | Empty draw mode — chrome at the **bottom** |
| [03_rectangle.png](./03_rectangle.png) | Closed 4000×3000 mm rectangle — same bottom bar |
| [04_edit_2d.png](./04_edit_2d.png) | Walls in the 2D editor |
| [05_edit_3d.png](./05_edit_3d.png) | Same walls in 3D |

Walls are SceneIR commands (`add_wall` / `move_wall` / `delete_wall` / `resize_wall`) via Session. Snap to axis and nearby endpoints. Length labels open the numeric sheet.

## Debug APK 0.1.7 (`versionCode` 8)

**每次构建升版本；签名固定.** Same debug cert as 0.1.0–0.1.6. Install over the previous build.

0.1.7 moves the 自由绘制 chrome (back / title / 完成 + tools) to the **bottom**.

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.7** (`versionCode` 8) arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `2f7b52003054f636e08b0b9d7aa4e612b1e3b7e1a86759c93f4ba3115dd21cc7` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/23jrpq.apk |
| Mirror | https://gofile.io/d/vtPCY7I3 |
