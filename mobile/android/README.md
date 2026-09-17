# Android host (legacy JNI stub)

> **Deprecated as the P0 APK path.** Product host is the Godot 4 project in
> [`godot/`](../../godot/README.md) (GDExtension → C API → SceneIR, export
> templates → APK). This Gradle/JNI app is kept for Fake-loop / JNI tests.
> Do not delete it abruptly.

Installable Kotlin app that links `toporoom_core` through JNI (`NativeCore` →
`toporoom.h`). P0 capture is **Android-first**; debug/emulator builds use
**Fake/Replay** so no USB depth module or Bluetooth laser is required.

Open this folder in Android Studio (`mobile/android/`). `assembleDebug` is the
Gradle target.

## Open in Android Studio

1. Install Android SDK 34 + NDK (side-by-side, CMake 3.22.1) and JDK 17+.
2. **File → Open** the folder `mobile/android/` (this directory is the Gradle
   application module).
3. Let Gradle sync. First native configure downloads Manifold + nlohmann via
   CMake FetchContent (needs network).
4. Run the `debug` variant on an emulator or device.

`local.properties` (not committed):

```properties
sdk.dir=/path/to/Android/sdk
```

## 白名单 + Fake/Replay（模拟器 / CI）

On launch the app loads `src/main/assets/android-whitelist.v1.json`. Emulator
models are **not** listed. **Debug** builds mark the 量房会话 host OK anyway and
show `Fake/Replay 量房 — 模拟器/调试包，无需深度模组或蓝牙激光`.

### Home（首页）

| 按钮 | 行为 |
|------|------|
| **新建方案** | `toporoom_document_create` + save SceneIR under `files/schemes/` |
| **引导量房** | Step UI: 画墙 → 门窗洞/垭口 → 关键尺寸 → 重建 → 导出 |
| **Fake 一室** | `toporoom_debug_fake_one_room` (4 walls, 2 Fake laser keys, door, export) |
| **导出 DXF/PDF（glb 若 OK）** | Writes `room.dxf` / `room.pdf`; `room.glb` only when Status is OK |

方案列表 loads saved `*.sceneir.json` plus a bundled
`rect-room-v02-archway-clearheight.sceneir.json` sample (垭口 + 净高 + 梁).
A 户型图 canvas draws walls and 门洞/窗洞/垭口 after edits.

### Guided flow (引导量房)

Each step writes `FloorPlanDocument` through the C API, then
`toporoom_guide_sync_from_document` observes SceneIR (same path as
`GuidedEditWorkflow`):

1. **画墙** — rectangle 4000×3000 mm
2. **门窗洞/垭口** — `OpeningKind` door / window / archway
3. **关键尺寸** — Fake 激光 queue 4000 / 3000, or 手输 mm with typed-explicit
4. **层高 / 净高 / 梁柱烟道** — storey height, room clearHeight, hosted beam/column/flue
5. **重建 → 导出** — close 客厅, sync guide, export to app storage

**一键引导编辑** calls `toporoom_document_run_guided_edit` (4 walls, 2 laser
keys, 垭口, 客厅 + 净高). That is the real edit path, not the debug Fake loop.

Exports land in `Android/data/com.toporoom.app/files/export/` (or
`files/export/`). SceneIR 方案 files: `files/schemes/<id>.sceneir.json`.

USB host + Bluetooth + nearby-device permissions are declared in the Manifest;
**申请 USB / 蓝牙 / 附近设备权限** is runtime scaffolding
(`BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`, `NEARBY_WIFI_DEVICES` on API 33+,
`UsbManager.requestPermission`). No vendor SDK binaries are bundled.

## Gradle from the CLI

```bash
cd mobile/android
./gradlew test          # JVM unit tests (GuideViewModel + SceneIrPlanParser + FakeTopoRoomBridge)
./gradlew assembleDebug # SDK 34 + NDK 26.1.10909125 + CMake 3.22.1
```

ViewModel tests do **not** load `libtoporoom_jni.so`; they use
`FakeTopoRoomBridge`. Guide completion rules (`≥2 laser` or typed explicit
with `≥2 typed`) live in C++ GoogleTest (`GuidedRoom`, `GuidedCaptureLoop`,
`EditingWorkflows`).

C++ `ctest` covers the new SceneIR save/load C API
(`toporoom_document_save` / `load` / `from_sceneir_json`).

Android Studio's CMake **3.22.1** cannot take `DOWNLOAD_EXTRACT_TIMESTAMP`
(CMake ≥ 3.24). `core/CMakeLists.txt` only passes that flag on newer CMake so
NDK configure can FetchContent nlohmann/json.

## What ran in this Cloud Agent VM vs local Android Studio

| Ran here | Needs local Android Studio / device |
|----------|-------------------------------------|
| `ctest` (C++ core, including C API save/load) | Install on a phone/emulator and tap through UI |
| `./gradlew test` (JVM ViewModel + parser) | Real Bluetooth laser / USB depth (out of P0 Fake) |
| `./gradlew assembleDebug` → APK with `libtoporoom_jni.so` for `arm64-v8a` + `x86_64` | Visual check of 户型图 canvas and exports on device |

Linux GitHub Actions CI still runs GoogleTest only; it does not assemble the APK.

## Layout

```
mobile/android/
  build.gradle.kts              application module (AGP 8.5 / Kotlin 1.9)
  CMakeLists.txt                libtoporoom_jni.so → ../../core
  src/main/cpp/toporoom_jni.cpp
  src/main/java/com/toporoom/core/NativeCore.java
  src/main/java/com/toporoom/app/
    MainActivity.kt             首页 + 引导量房 UI
    GuideViewModel.kt           JNI session
    TopoRoomBridge.kt           C API façade + JniTopoRoomBridge
    PlanSnapshot.kt             SceneIR 0.2 → 户型图 snapshot
    PlanCanvasView.kt           wall / opening canvas
  src/main/assets/{android-whitelist.v1,release-train.v1,
                   rect-room-v02-archway-clearheight.sceneir}.json
  src/test/java/.../GuideViewModelTest.kt
```
