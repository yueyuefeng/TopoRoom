# JoyPlan 1:1 chrome (video frames)

References are stills from the user-supplied JoyPlan video. Product captures
are rendered from `godot/app/capture_ui.gd`.

Boot: **system photo picker** (`ref_picker.jpg`). There is no dual-card
camera/gallery home.

| Ours | Reference | Screen |
|------|-----------|--------|
| [s2_scale.png](./s2_scale.png) | [ref_s2_scale.jpg](./ref_s2_scale.jpg) | Scale setting + black Exit / Adjust / enter length / orange OK |
| [s3_2d.png](./s3_2d.png) | [ref_s3_2d.jpg](./ref_s3_2d.jpg) | 4-mode capsule, L/∠, green FAB, undo/redo, orange select |
| [s4_library_sheet.png](./s4_library_sheet.png) | [ref_s4_library.jpg](./ref_s4_library.jpg) | 2D + library sheet / green + |
| [s5_3d.png](./s5_3d.png) | [ref_s5_3d.jpg](./ref_s5_3d.jpg) | 4-mode cube, right rail, + / library / sun |
| | [ref_picker.jpg](./ref_picker.jpg) | System photo picker (OS UI) |

## Debug APK

**每次构建升版本；签名固定.** APK is gitignored (`*.apk`).

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.1** (`versionCode` 2) arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `ae9cd82e7383a37105effdb623e424fde0fb261e801a0c1ec23f040b9cd048ea` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/i352c3.apk |
| Mirror | https://gofile.io/d/LgzMX1WS |

Same signature as **0.1.0** so the phone can upgrade without uninstall. Keystore: `godot/android/keystore/debug.keystore`. Contains `lib/arm64-v8a/libtoporoom.android.template_debug.arm64.so`. Export filter excludes `app/_legacy/*`. Camera / gallery / vibrate + `READ_MEDIA_IMAGES` present. `main.tscn` boots `joyplan_flow/home.tscn`, which opens the system picker (`pick_gallery`). `TopoRoomMedia` is in `classes.dex` (`ACTION_PICK_IMAGES`, `BitmapFactory`).
