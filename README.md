# 拓间 TopoRoom — P0 software core

Low-cost Type-C depth + phone host + Bluetooth **laser** anchors → editable floor-plan semantics (**SceneIR**) → professional export. This repository currently contains the **testable TypeScript core** (no Android APK).

Specs (source of truth):

- [docs/architecture/FINAL-readme.md](./docs/architecture/FINAL-readme.md) — hard decisions
- [docs/architecture/FINAL-toporoom-hw-sw-requirements.md](./docs/architecture/FINAL-toporoom-hw-sw-requirements.md) — FR/NFR, P0 In/Out
- [docs/architecture/FINAL-toporoom-software-architecture.md](./docs/architecture/FINAL-toporoom-software-architecture.md) — packages, ports, BC map

## Quick start

```bash
pnpm install
pnpm test
pnpm lint
pnpm typecheck
```

Requires Node.js ≥ 20 and pnpm 10.

## Invariants (I1–I10)

| # | Rule |
|---|------|
| **I1** | SceneIR / `FloorPlanDocument` is the only editable source of truth. Mesh, point cloud, 3DGS, Godot nodes are derivatives. |
| **I2** | `manifold` exists only behind the GeometryKernel ACL. Aggregates, events, and `DocumentStore` never hold `Manifold` / `CrossSection` / `MeshGL`. |
| **I3** | gotbot contributes Application patterns only (`ToolRegistry`, `ParamGatheringFSM`, `SessionIsolate`). It is not a CAD kernel. |
| **I4** | Writes are **serial per `documentId`**. Rebuild may pre-empt via `rebuildGeneration`. |
| **I5** | Capture emits Command/Event into the same `FloorPlanDocument`. No second truth document. |
| **I6** | Structural-solid export requires Status == OK. Faults are visible; never silently ship a bad mesh. |
| **I7** | Godot is a read-only glTF host. Editing stays in TopoRoom. |
| **I8** | VisualizationDerivative must not write dimensions back. |
| **I9** | Laser lengths are written through Command into semantics **with `source`**. Evidence-only is not a measurement. |
| **I10** | Dependencies: UI → Application → Domain ← Adapters. Ports inside, adapters outside. |

Hard product decisions: slim P0 (no MEP / furnishing / cloud / quote), laser in P0, no GS write-back, Android whitelist later, RF BLE ranging is **never** a dimension source.

## Packages

```text
packages/
  domain-floorplan/          # LengthMm, Wall/Storey/Opening, FloorPlanDocument, SceneIR 0.1
  ports/                     # GeometryPort, LaserRangefinderPort, DepthStreamPort,
                             # DocumentStorePort, NotifyPort (+ fakes)
  app-interaction-shell/     # SessionIsolate, ParamGatheringFSM, ToolRegistry, WallDrawTool
  app-floorplan/             # AddWall / AddOpening / SetMeasurement + RebuildPolicy
  app-deliverables/          # StatusGate + ExportAppService
  adapter-export-gltf/       # Scene-graph JSON + minimal glTF 2.0 JSON (mm→m)
  fixtures-sceneir/          # SceneIR 0.1 rectangular-room gold fixture
  adapter-manifold-wasm/     # TODO — real CrossSection→Extrude→Boolean
  adapter-depth-vendorsdk/   # stub
  adapter-depth-uvc/         # stub
  adapter-laser-bt/          # stub
  adapter-imu-phone/         # stub
  adapter-store-indexeddb/   # stub
  adapter-export-dxf/        # stub
```

CI also enforces **NFR-015**: `domain-*` must not import `manifold` / `three` / `godot` (ESLint + a source scan test).

## Hardware adapters (later)

Depth, laser, and IMU talk to the core **only** through ports. This milestone ships `FakeGeometryPort` and in-memory document store. Real drivers, Android USB/BT, and Godot are out of scope here.

## Next TDD slices

1. `domain-capture` / `app-capture` — `CaptureSession` AR, guided FSM (calibrate → outer wall → height → openings), draft save / resume.
2. `adapter-manifold-wasm` — real GeometryPort; Fault mapping; cache key = hash(SceneIR slice + compile options).
3. Typed + Bluetooth `LaserRangefinderPort` adapters; never RF-BLE as a ruler.
4. `DepthStreamPort` VendorSdk (primary) + UVC (transport) with replay fixtures (NFR-006).
5. `adapter-export-dxf` / PDF; Q3: whether semantic DXF mid-line layers may export on Fault.
6. IndexedDB `DocumentStorePort`; EvidencePack weak refs (deletable).
7. Android host: whitelist hex tuple, USB/BT permissions, experimental-mode watermark.
8. Godot 4 read-only `.glb` roam; no SceneIR write-back.

## Measurement sources (SceneIR 0.1)

`measurements[].source ∈ { laser, typed, depth_fit }`

`depth_fit` must not silently overwrite `laser` or `typed`.
