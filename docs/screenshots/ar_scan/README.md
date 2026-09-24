# AR扫描

新建户型 → **AR扫描** → camera-guided measure (ARCore plane hit-test when present) → **完成** → existing 2D / 3D.

TopoRoom P0 is **not** LiDAR-only. No depth accessory is required. Emulator / no-ARCore devices degrade to 引导量墙 + **演示房间**.

| File | Screen |
|------|--------|
| [01_new_plan.png](./01_new_plan.png) | 新建户型 — AR扫描 is a real entry (not a toast) |
| [02_scan_ui.png](./02_scan_ui.png) | Dedicated AR scan viewfinder + 标记墙角 |
| [03_demo_room.png](./03_demo_room.png) | Closed 4000×3000 mm outline after 演示房间 |
| [04_edit_2d.png](./04_edit_2d.png) | Existing 2D editor with SceneIR `wall_a*` |
| [05_edit_3d.png](./05_edit_3d.png) | 3D toggle still works |

Walls are SceneIR commands (`add_wall` via `Session.add_ar_wall` / `commit_ar_polyline`). Kernel helper: `toporoom_document_add_polyline_walls`.

## Debug APK 0.1.9 (`versionCode` 10)

**每次构建升版本；签名固定.** Same debug cert as 0.1.0–0.1.8. Install over the previous build.

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.9** (`versionCode` 10) arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (75 MB) |
| SHA-256 | `26f7e07ad611dc6fd478560cf36dad3404c5c456e1171088f6c6cb6f67c89286` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/83ozjj.apk |
| Mirror | https://gofile.io/d/VtaKK0Su |
