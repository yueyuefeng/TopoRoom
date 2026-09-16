# 拓间 TopoRoom

**C++ only.** No TypeScript, no JavaScript, no pnpm/npm workspace. The
editable product core is a CMake static library consumed by native **iOS**
and **Android** hosts through a C API (`core/include/toporoom/c_api/toporoom.h`).

Low-cost Type-C depth + phone host + Bluetooth **laser** anchors → editable
floor-plan semantics (**SceneIR**) → professional export (DXF / PDF / glTF).

Specs:

- [docs/architecture/FINAL-readme.md](./docs/architecture/FINAL-readme.md)
- [docs/architecture/FINAL-toporoom-hw-sw-requirements.md](./docs/architecture/FINAL-toporoom-hw-sw-requirements.md)
- [docs/architecture/FINAL-toporoom-software-architecture.md](./docs/architecture/FINAL-toporoom-software-architecture.md)

## Quick start (Linux CI)

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DTOPOROOM_BUILD_TESTS=ON -DCMAKE_CXX_COMPILER=g++
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

Requires CMake ≥ 3.20, a C++20 compiler, and network on first configure
(GoogleTest + nlohmann/json + [elalish/manifold](https://github.com/elalish/manifold)
v3.5.3 via FetchContent).

## Layout

```text
core/                 C++ domain, ports, app services, fakes, SceneIR JSON, C API
  include/toporoom/
  src/
  tests/              GoogleTest (ctest)
  fixtures/           SceneIR 0.1 gold JSON, whitelist, release-train
godot/                Godot 4 read-only .glb roam (no SceneIR write-back)
mobile/android/       Gradle app + JNI (Fake/Replay in debug)
mobile/ios/           Xcode SwiftUI shell + ObjC++ (software host)
docs/architecture/    FINAL specs
```

## How mobile hosts consume the core

```
        Swift UI (iOS)                 Kotlin/Java UI (Android)
                │                                │
                ▼                                ▼
        TopoRoomCore.mm                    NativeCore JNI
                │                                │
                └──────────► C API (toporoom.h) ◄┘
                                   │
                                   ▼
                         toporoom_core (C++)
                         FloorPlanDocument = SceneIR
```

- SceneIR / `FloorPlanDocument` is the only editable truth (I1).
- Godot, if used at all, is a **read-only** glTF consumer. It does not write
  dimensions back.
- iOS is a first-class host for the **software** core; P0 hardware capture
  (Type-C depth whitelist) remains Android-first per the FINAL hardware spec.

### Android Studio (P0 primary host)

Open `mobile/android/` as a Gradle project (SDK 34 + NDK + CMake 3.22). Debug
builds load `android-whitelist.v1.json` then **bypass** an unlisted emulator
with Fake/Replay. Tap **Run Fake one-room loop** to draw walls, apply two
laser keys, place a door, rebuild, and write `room.glb` / `room.dxf` /
`room.pdf` under app storage. See [mobile/android/README.md](./mobile/android/README.md).

`./gradlew assembleDebug` needs a local Android SDK/NDK. Linux CMake CI does
not assemble the APK; it runs GoogleTest only. JVM `GuideViewModel` tests:
`./gradlew test` (also needs the Android Gradle plugin / SDK).

### Xcode (software host)

Open `mobile/ios/TopoRoom.xcodeproj`, scheme **TopoRoom**. Link
`libtoporoom_core.a` from a CMake build (`build/core`). UI copy:
**P0: depth capture Android-first**. Same Fake one-room C API, or typed
millimetres. See [mobile/ios/README.md](./mobile/ios/README.md). No Mac pool
in this CI — sources + scheme only.

## Invariants (I1–I10)

| # | Rule |
|---|------|
| **I1** | SceneIR / `FloorPlanDocument` is the only editable source of truth. |
| **I2** | `manifold` exists only behind GeometryPort adapters. Domain never holds Manifold/MeshGL. |
| **I3** | Interaction shell is Application: `ToolRegistry`, `ParamGatheringFSM`, `SessionIsolate`. |
| **I4** | Writes are serial per `documentId`. |
| **I5** | Capture emits commands into the same `FloorPlanDocument`. |
| **I6** | Structural-solid export requires Status == OK. Faults reject export. |
| **I7** | Godot is a read-only glTF host. |
| **I8** | VisualizationDerivative must not write dimensions back. |
| **I9** | Laser lengths go through Command into semantics with `source`. |
| **I10** | UI → Application → Domain ← Adapters. |

CI scans `core/**/domain/**` so it cannot include manifold / three / godot /
nlohmann JSON (JSON stays in adapters).

## TDD slices

1. ~~Manifold **native** GeometryPort (`CrossSection → Extrude → Boolean`).~~ **Done**
2. ~~DXF / PDF / `.glb` exporters and Godot read-only roam.~~ **Done**
3. ~~Bluetooth `LaserRangefinderPort` + typed fallback (`source=laser|typed`).~~ **Done**
   (CI uses `FakeBleLaserTransport` / `ReplayLaserPort`; no real radio.)
4. ~~`DepthStreamPort` VendorSdk + UVC + replay fixture; Android whitelist.~~ **Done**
   (`core/fixtures/android-whitelist.v1.json`; iOS external depth stays out of P0.)
5. ~~JNI/NDK + Swift UI: guided capture, runtime permission prompts, USB/BT UX.~~ **Done**
   (`GuidedRoomSession`: host OK, ≥4 walls, ≥1 opening, rebuild OK, and ≥2 laser
   key edges **or** typed explicit with ≥2 typed. `EvidencePack` sidecar may be
   empty. `release-train.v1.json` maps software tag ↔ module SKU / firmware /
   whitelist file version.)

`measurements[].source ∈ { laser, typed, depth_fit }`. `depth_fit` must not
silently overwrite `laser` or `typed`. RF BLE ranging is never a ruler.
