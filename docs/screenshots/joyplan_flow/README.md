# JoyPlan flow screenshots (S1–S8)

Floating-island chrome captured from `godot/app/capture_ui.gd` against the
new `joyplan_flow/` scene graph. Not the quarantined `_legacy/` workbench.

| File | Screen |
|------|--------|
| s1_home.png | JoyPlan home: 我的项目 / AI厨房 |
| s2_scale_calibration.png | 比例设置 + dark 调整户型 sheet |
| s2_scale_loupe.png | Circular loupe while dragging a handle |
| s3_2d_base_edit.png | 2D\|3D capsule + 3-icon dock + contextual pill |
| s4_library_sheet.png | 收藏/门/窗/梁管/电气 + 长按 coach |
| s5_3d_walkthrough.png | Right circles, minimap FOV, green 2D, undo/redo |
| s6_ruler_sheet.png | Ruler display |
| s7_dimension_hud.png | Pink in-world dimensions |
| s8_elevation_index.png | Elevation Index stub |

## Debug APK

**每次构建升版本；签名固定.** APK is gitignored (`*.apk`). Built on this branch:

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.7** (`versionCode` 8) arm64-v8a |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `2f7b52003054f636e08b0b9d7aa4e612b1e3b7e1a86759c93f4ba3115dd21cc7` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/23jrpq.apk |
| Mirror | https://gofile.io/d/vtPCY7I3 |

Same signature as **0.1.0–0.1.6** — install over the previous Debug APK without uninstall. Contains `lib/arm64-v8a/libtoporoom.android.template_debug.arm64.so`. Export filter excludes `app/_legacy/*`. Camera / gallery / vibrate permissions present. `main.tscn` boots JoyPlan home (我的项目 → 工程项目 → **自由绘制** / 导入户型图). Free-draw captures: `docs/screenshots/free_draw/`.
