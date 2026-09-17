# TopoRoom core

C++20 static library: SceneIR domain, ports, application services, C API.

Production geometry is `ManifoldGeometryPort` (CrossSection → Extrude →
Boolean). Deliverables: binary `.glb` (mm→m once), ASCII DXF, and a simple
PDF floor plan — all gated by StatusGate. Capture adapters: Bluetooth laser
(fake/replay in CI), VendorSdk + UVC depth (replay fixture), Android
whitelist v1, IMU degrade stubs. Guided one-room FSM (`GuidedRoomSession` / `CaptureSession` 量房会话),
empty-OK `EvidencePack` sidecar, and `ReleaseTrain` JSON live in app/adapters.
P0 editing: `FloorPlanEditService` (wall/opening/room/storey/hosted/measurement
commands, SessionIsolate), tools `WallDraw` / `PlaceOpening` / `PlaceHostedComponent`
/ `SetClearHeight` / `SetStoreyHeight`, and `GuidedEditWorkflow` (real multi-step
量房, not only `debug_fake_one_room`). C API also create/load/save SceneIR 方案
(`toporoom_document_save` / `load` / `from_sceneir_json`).
P1+ ports (MEP / furnishing / cloud sync / quote) are `NotImplemented*` stubs
returning `NotInP0` (FR-013) — not P0 Done gates.
Domain sources must not `#include` manifold or vendor SDKs — see
`core/adapters/STUBS.md` and NFR-015.
