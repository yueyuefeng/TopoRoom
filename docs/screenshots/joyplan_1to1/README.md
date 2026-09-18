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

APK is gitignored (`*.apk`). Built on this branch after picker-first + 1:1 chrome.

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.0** arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `b719c565a9baf9a45f7811d65dcdddaae8e775451739838254b766fa6b1a5b76` |
| Direct | https://litter.catbox.moe/pr1zsb.apk |
| Mirror | https://gofile.io/d/ayxTdhvh |

Contains `lib/arm64-v8a/libtoporoom.android.template_debug.arm64.so`. Export filter excludes `app/_legacy/*`. Camera / gallery / vibrate + `READ_MEDIA_IMAGES` present. `main.tscn` boots `joyplan_flow/home.tscn`, which opens the system picker (`pick_gallery`). `TopoRoomMedia` is in `classes.dex` (`ACTION_PICK_IMAGES`, `BitmapFactory`).
