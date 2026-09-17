# Android host

Installable Kotlin app that links `toporoom_core` through JNI (`NativeCore` →
`toporoom.h`). P0 capture is **Android-first**; debug/emulator builds use
**Fake/Replay** so no USB depth module or Bluetooth laser is required.

Locked PoC SKU (see [docs/hardware/ADR-001-poc-module-selection.md](../../docs/hardware/ADR-001-poc-module-selection.md)):

- Depth: **Orbbec Gemini E** (`orbbec_gemini_e`, FW **3460**, VID `2BC5` PID `065C`)
- Laser: TopoRoom hub GATT (`toporoom_hub_c3` FW **0.1.0`) bridging a UART JRT/Meskernel module
- IMU: phone IMU (degraded). Gemini E has no onboard IMU.

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

## Hardware bring-up (Stage-Gate)

Checklist: [docs/hardware/stage-gate-poc-checklist.md](../../docs/hardware/stage-gate-poc-checklist.md).

### 1. Depth — Gemini E on phone USB Host

Gemini E is a **USB device**. The phone is the **USB host** (OTG). The ESP32
hub does **not** proxy this camera.

1. Prefer a **powered USB 2/3 hub** between phone and Gemini E (`hubSku=powered_hub_a`).
   Naked OTG (`hubSku=none`) only if that phone survives a 30-minute stream.
2. Grant **USB Host** when the attach dialog appears (filter VID/PID `2BC5`/`065C`).
3. Official Orbbec AAR is **not** in this repo. Follow [ORBBEC.md](./ORBBEC.md)
   to link it, then `OrbbecGeminiEDepthAdapter` can be wired. Until then the
   C++ adapter throws “SDK not linked” and debug Fake/Replay still works.
4. Do not treat depth as millimetre-everywhere. Laser (or explicit typed) is
   the critical-edge source.

### 2. Laser — flash the companion hub, then GATT

1. Wire JRT M88B / Meskernel LDL-T UART at 3.3 V per
   [firmware/toporoom-hub/PINOUT.md](../../firmware/toporoom-hub/PINOUT.md).
2. `cd firmware/toporoom-hub && pio run -e esp32-c3 -t upload`
   (no laser module yet: `-e esp32-c3-sim`).
3. nRF Connect: device **TopoRoom Hub**, service `a100`, write `01 01 E8 03`
   on measure, enable notify on length. See
   [firmware/toporoom-hub/PROTOCOL.md](../../firmware/toporoom-hub/PROTOCOL.md).
4. In the app: grant Bluetooth → **Scan / connect TopoRoom hub** →
   **Measure key (BLE hub laser)**. **Measure key (laser Fake/Replay)** remains
   for emulator/CI.
5. RF / RSSI is never stored as `source=laser`.

### 3. Whitelist + ReleaseTrain

Launch loads `src/main/assets/android-whitelist.v1.json` and
`release-train.v1.json`:

`0.1.0` ↔ `orbbec_gemini_e` **3460** ↔ hub **0.1.0** ↔ whitelist v1.

Unlisted emulator: debug builds mark host-OK with Fake/Replay.

## Fake capture loop (emulator / CI)

On launch the app loads `src/main/assets/android-whitelist.v1.json`. Emulator
models are **not** listed. **Debug** builds mark the guide host OK anyway and
show `Fake/Replay capture — emulator/debug, no hardware`.

Tap **Run Fake one-room loop**. That calls `toporoom_debug_fake_one_room`:

1. four exterior walls (4000×3000 mm)
2. two **laser** key edges (queued Fake lengths 4000 / 3000)
3. one door opening
4. close room
5. export `room.glb`, `room.dxf`, `room.pdf` to app storage
   (`Android/data/com.toporoom.app/files/export/` or `files/export/`)

Step-by-step buttons (draw walls → laser Fake or typed explicit → door →
rebuild/export) drive the same C++ `GuidedRoomSession` via JNI.

USB host + Bluetooth permissions are declared in the Manifest;
**Request USB host / Bluetooth permissions** is runtime scaffolding
(`BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`, `UsbManager.requestPermission`).
No vendor SDK binaries are bundled.

## Gradle from the CLI

```bash
cd mobile/android
./gradlew test          # JVM unit tests (GuideViewModel + FakeTopoRoomBridge + GATT codec)
./gradlew assembleDebug # needs SDK + NDK; not run in the Linux CMake CI
```

ViewModel tests do **not** load `libtoporoom_jni.so`; they use
`FakeTopoRoomBridge`. Guide completion rules (`≥2 laser` or typed explicit
with `≥2 typed`) live in C++ GoogleTest (`GuidedRoom`, `GuidedCaptureLoop`).

## Layout

```
mobile/android/
  build.gradle.kts              application module (AGP 8.5 / Kotlin 1.9)
  CMakeLists.txt                libtoporoom_jni.so → ../../core
  ORBBEC.md                     how to link the official Orbbec AAR
  src/main/cpp/toporoom_jni.cpp
  src/main/java/com/toporoom/core/NativeCore.java
  src/main/java/com/toporoom/app/{MainActivity,GuideViewModel}.kt
  src/main/java/com/toporoom/hw/  Gemini E constants + BLE hub GATT client
  src/main/assets/{android-whitelist.v1,release-train.v1}.json
  src/test/java/.../GuideViewModelTest.kt
  src/test/java/com/toporoom/hw/HubGattCodecTest.kt
```
