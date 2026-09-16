# Android host

Installable Kotlin app that links `toporoom_core` through JNI (`NativeCore` →
`toporoom.h`). P0 capture is **Android-first**; debug/emulator builds use
**Fake/Replay** so no USB depth module or Bluetooth laser is required.

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
./gradlew test          # JVM unit tests (GuideViewModel + FakeTopoRoomBridge)
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
  src/main/cpp/toporoom_jni.cpp
  src/main/java/com/toporoom/core/NativeCore.java
  src/main/java/com/toporoom/app/{MainActivity,GuideViewModel}.kt
  src/main/assets/{android-whitelist.v1,release-train.v1}.json
  src/test/java/.../GuideViewModelTest.kt
```
