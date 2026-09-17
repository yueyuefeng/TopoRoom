# Android host

Installable Kotlin app that links `toporoom_core` through JNI (`NativeCore` →
`toporoom.h`). P0 capture is **Android-first**; debug/emulator builds use
**Fake/Replay**.

Hardware story (not a Gemini E lock): [ADR-001](../../docs/hardware/ADR-001-poc-module-selection.md).

- Depth SKU is **pluggable**: `dabai_dcw` (Track A, ~¥788 ASIC) | `dual_rgb_uvc` (Track B ¥200-band UVC assist) | `fake`
- Laser: TopoRoom hub GATT (`toporoom_hub_c3` FW **0.1.0**) + UART JRT/Meskernel — **both tracks**
- IMU: phone IMU (degraded)
- **No** ¥200 ready-made ASIC depth Type-C accessory is claimed

## Open in Android Studio

1. Install Android SDK 34 + NDK (side-by-side, CMake 3.22.1) and JDK 17+.
2. **File → Open** the folder `mobile/android/`.
3. Let Gradle sync (FetchContent needs network on first native configure).
4. Run the `debug` variant.

`local.properties` (not committed):

```properties
sdk.dir=/path/to/Android/sdk
```

## Hardware bring-up

Checklist: [docs/hardware/stage-gate-poc-checklist.md](../../docs/hardware/stage-gate-poc-checklist.md).

### Laser hub (both tracks)

1. Wire UART laser at 3.3 V: [firmware/toporoom-hub/PINOUT.md](../../firmware/toporoom-hub/PINOUT.md).
2. `cd firmware/toporoom-hub && pio run -e esp32-c3 -t upload` (or `-e esp32-c3-sim`).
3. nRF Connect: **TopoRoom Hub**, write `01 01 E8 03`, notify on length.
4. App: **Scan / connect TopoRoom hub** → **Measure key (BLE hub laser)**.
   **Measure key (laser Fake/Replay)** remains for emulator/CI.
5. RF / RSSI is never `source=laser`.

### Track A — DaBai DCW (optional ASIC depth)

Phone is USB **host**. ESP32 does **not** proxy the camera.

1. Prefer a **powered USB hub**. Confirm the listing connector (Type-C vs Micro vs pigtail).
2. VID `2BC5`; record PID from the unit.
3. Official OpenNI/SDK is **not** in git. See [DEPTH.md](./DEPTH.md).
4. Depth is not millimetre-everywhere.

### Track B — dual RGB UVC assist

UVC preview is **color**, not an ASIC depth stream. `depth_fit` must stay low-confidence.

### Whitelist + ReleaseTrain

`0.1.0` ↔ hub **0.1.0** ↔ whitelist v1 ↔ **one of** `fake/replay`, `dabai_dcw/2460`, `dual_rgb_uvc/uvc_host`.

Unlisted emulator: debug builds mark host-OK with Fake/Replay.

## Fake capture loop (emulator / CI)

Tap **Run Fake one-room loop** (`toporoom_debug_fake_one_room`): 4 walls, 2 Fake laser keys, door, export `room.{glb,dxf,pdf}`.

## Gradle CLI

```bash
cd mobile/android
./gradlew test
./gradlew assembleDebug   # needs SDK+NDK; not in Linux CMake CI
```

## Layout

```
mobile/android/
  DEPTH.md                      Track A/B SDK notes (no vendored blobs)
  src/main/java/com/toporoom/hw/  DepthSku + BLE hub GATT client
  src/main/assets/{android-whitelist.v1,release-train.v1}.json
```
