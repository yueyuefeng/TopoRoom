# 拓间 TopoRoom

**C++ only.** No TypeScript, no JavaScript, no pnpm/npm workspace. The
editable product core is a CMake static library consumed by native **iOS**
and **Android** hosts through a C API (`core/include/toporoom/c_api/toporoom.h`).

Low-cost Type-C depth + phone host + Bluetooth **laser** anchors → editable
floor-plan semantics (**SceneIR 0.2**, 方案/户型文档) → 户型图 export (DXF / PDF / glTF).

Specs:

- [docs/architecture/FINAL-readme.md](./docs/architecture/FINAL-readme.md)
- [docs/architecture/FINAL-toporoom-hw-sw-requirements.md](./docs/architecture/FINAL-toporoom-hw-sw-requirements.md)
- [docs/architecture/FINAL-toporoom-software-architecture.md](./docs/architecture/FINAL-toporoom-software-architecture.md)
- [docs/architecture/FINAL-toporoom-domain-model.md](./docs/architecture/FINAL-toporoom-domain-model.md)

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
with Fake/Replay. Home: **新建方案** / **Fake 一室** / **引导量房** / **导出**.
Guided flow: 画墙 → 门窗洞/垭口 → 关键尺寸 (Fake 激光 or 手输) → 重建 → 导出
DXF/PDF (`glb` only when Status is OK). See
[mobile/android/README.md](./mobile/android/README.md).

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
   whitelist file version.) Android host (`mobile/android`) is an installable
   Gradle app: JNI covers create/load/save 方案, wall/opening/room/hosted edits,
   `GuidedEditWorkflow` C API, and DXF/PDF/(glb-when-OK) export. Debug builds
   run Fake/Replay without hardware.
6. ~~P1+ reserved ports (MEP / soft furnishing / cloud sync / auto quote).~~ **Stubs only**
   (**FR-013**: not P0 Done gates). See [P1+ reserved ports](#p1-reserved-ports-fr-013).
7. ~~Industry Domain model (OpeningKind 门窗垭口, 层高≠净高, SceneIR 0.2).~~ **Done**
   `GuidedRoomSession` = 量房会话 (`CaptureSession`). P0 drawing = 户型图.
   Fault still emits semantic DXF; glb structural solid is rejected.
8. ~~Business + editing workflows (commands, tools, guided multi-step).~~ **Done**
   See [Edit commands](#edit-commands).

`measurements[].source ∈ { laser, typed, depth_fit }`. `depth_fit` must not
silently overwrite `laser` or `typed`. RF BLE ranging is never a ruler.

## Edit commands

Application service `FloorPlanEditService` writes the 方案 (`FloorPlanDocument`)
serially per `documentId` (`SessionIsolate`). Tools gather parameters
(`ParamGatheringFSM` + `ToolRegistry`) then commit those commands.

| Command | Tool id | Notes |
|---------|---------|-------|
| Add / Move / Resize / Delete **Wall** | `WallDrawTool` | Resize keeps start, scales end |
| Add / Update / Delete **Opening** | `PlaceOpening` | `OpeningKind` door\|window\|**archway** (垭口) required |
| Close room + set name / `SpaceType` / optional **clearHeightMm** (净高) | `SetClearHeight` | 层高 is `Storey.height`, not 净高 |
| Change **Storey** 层高 | `SetStoreyHeight` | Default matching walls follow; `set_wall_height` overrides |
| Add / Update / Delete **HostedComponent** | `PlaceHostedComponent` | beam\|column\|flue (梁/柱/烟道); optional `hostWallId` |
| SetMeasurement | (capture / typed) | source laser\|typed\|depth_fit on key edges |

`GuidedEditWorkflow` drives a real multi-step 量房 path (4 walls, ≥2 laser or
typed-explicit keys, ≥1 opening, rebuild OK) instead of only
`toporoom_debug_fake_one_room`. C API mirrors the document edits plus
`toporoom_document_run_guided_edit` / `toporoom_guide_sync_from_document`.

P0 drawing = **户型图**. Fault still emits semantic-line DXF/PDF and rejects glb solids.

## P1+ reserved ports (FR-013)

P0 software scope must **not** treat MEP, a soft-furnishing library, cloud
sync, or auto quoting as acceptance blockers. Ports are reserved so P1 BCs
can plug in later; they are not registered on the P0 guide/export path.

| Port | Adapter | Call result |
|------|---------|-------------|
| `MepPort` (points / polylines) | `NotImplementedMepAdapter` | `NotInP0` |
| `FurnishingLibraryPort` | `NotImplementedFurnishingAdapter` | `NotInP0` |
| `CloudSyncPort` (push/pull document) | `NotImplementedCloudSyncAdapter` | `NotInP0` |
| `TakeoffQuotePort` | `NotImplementedQuoteAdapter` | `NotInP0` |

GoogleTest suite `OutOfScopeP1` proves a fake one-room guide+export succeeds
with none of these ports wired, and that invoking a stub returns `NotInP0`.
No MEP/soft/cloud/quote business logic is implemented.
