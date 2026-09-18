# JoyPlan 1:1 chrome (video frames)

References are stills from the user-supplied JoyPlan video. Product captures
are rendered from `godot/app/capture_ui.gd`.

Boot: **usable home** (`s1_home.png`) with 示例户型 / 相册导入 / 拍照.
示例户型 needs no permissions. Picker is opt-in; cancel stays on this home.

| Ours | Reference | Screen |
|------|-----------|--------|
| [s1_home.png](./s1_home.png) | [ref_picker.jpg](./ref_picker.jpg) | Home: 示例户型 / 相册导入 / 拍照 |
| [s2_scale.png](./s2_scale.png) | [ref_s2_scale.jpg](./ref_s2_scale.jpg) | Scale setting + black Exit / Adjust / enter length / orange OK |
| [s3_2d.png](./s3_2d.png) | [ref_s3_2d.jpg](./ref_s3_2d.jpg) | 4-mode capsule, L/∠, green FAB, undo/redo, orange select |
| [s4_library_sheet.png](./s4_library_sheet.png) | [ref_s4_library.jpg](./ref_s4_library.jpg) | 2D + library sheet / green + |
| [s5_3d.png](./s5_3d.png) | [ref_s5_3d.jpg](./ref_s5_3d.jpg) | 4-mode cube, right rail, + / library / sun |
| | [ref_picker.jpg](./ref_picker.jpg) | System photo picker (OS UI) |

## Debug APK

**每次构建升版本；签名固定.** APK is gitignored (`*.apk`).

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.3** (`versionCode` 4) arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (75 MB) |
| SHA-256 | `4cc05819eef053502ce39650a549c3fc4e2c694a74b46bffeee319b0a41562b5` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/fqpplb.apk |
| Mirror | https://gofile.io/d/coQM7vIP |

Same signature as **0.1.0** so the phone can upgrade without uninstall. Keystore: `godot/android/keystore/debug.keystore`. Contains `lib/arm64-v8a/libtoporoom.android.template_debug.arm64.so`. Export filter excludes `app/_legacy/*`. Camera / gallery / vibrate + `READ_MEDIA_IMAGES` present. `main.tscn` boots JoyPlan home (我的项目 → 工程项目 → 导入户型图). `TopoRoomMedia` is in `classes.dex`. Click-path captures: `docs/screenshots/joyplan_click_path/`.
