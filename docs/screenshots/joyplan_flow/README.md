# JoyPlan flow screenshots (S1–S8)

Floating-island chrome captured from `godot/app/capture_ui.gd` against the
new `joyplan_flow/` scene graph. Not the quarantined `_legacy/` workbench.

| File | Screen |
|------|--------|
| s1_home.png | 拍户型 / 相册 |
| s2_scale_calibration.png | 比例设置 + dark 调整户型 sheet |
| s2_scale_loupe.png | Circular loupe while dragging a handle |
| s3_2d_base_edit.png | 2D\|3D capsule + 3-icon dock + contextual pill |
| s4_library_sheet.png | 收藏/门/窗/梁管/电气 + 长按 coach |
| s5_3d_walkthrough.png | Right circles, minimap FOV, green 2D, undo/redo |
| s6_ruler_sheet.png | Ruler display |
| s7_dimension_hud.png | Pink in-world dimensions |
| s8_elevation_index.png | Elevation Index stub |

## Debug APK

APK is gitignored (`*.apk`). Built on this branch:

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.0** arm64-v8a |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `b719c565a9baf9a45f7811d65dcdddaae8e775451739838254b766fa6b1a5b76` |
| Direct | https://litter.catbox.moe/pr1zsb.apk |
| Mirror | https://gofile.io/d/ayxTdhvh |

Contains `lib/arm64-v8a/libtoporoom.android.template_debug.arm64.so`. Export filter excludes `app/_legacy/*`. Camera / gallery / vibrate permissions present. `main.tscn` boots `joyplan_flow/home.tscn` (system photo picker, no dual-card home). 1:1 captures: `docs/screenshots/joyplan_1to1/`.
