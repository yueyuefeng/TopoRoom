# TopoRoom core

C++20 static library: SceneIR domain, ports, application services, C API.

Production geometry is `ManifoldGeometryPort` (CrossSection → Extrude →
Boolean). Deliverables: binary `.glb` (mm→m once), ASCII DXF, and a simple
PDF floor plan — all gated by StatusGate. Capture adapters: Bluetooth laser
(fake/replay in CI), VendorSdk + UVC depth (replay fixture), Android
whitelist v1, IMU degrade stubs. Guided one-room FSM (`GuidedRoomSession` / `CaptureSession` 量房会话),
empty-OK `EvidencePack` sidecar, and `ReleaseTrain` JSON live in app/adapters.
P1+ ports (MEP / furnishing / cloud sync / quote) are `NotImplemented*` stubs
returning `NotInP0` (FR-013) — not P0 Done gates.
Domain sources must not `#include` manifold or vendor SDKs — see
`core/adapters/STUBS.md` and NFR-015.
