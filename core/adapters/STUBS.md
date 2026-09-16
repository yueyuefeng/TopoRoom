# Hardware / geometry adapters (later)

These are **not** implemented in this milestone. They will live as C++
adapter libraries that implement ports in `core/include/toporoom/ports`.

| Adapter | Port | Notes |
|---------|------|--------|
| manifold native | GeometryPort | **P0 done** — `ManifoldGeometryPort`: CrossSection → Extrude → Boolean; only adapter that may include manifold (`elalish/manifold` v3.5.3) |
| manifold WASM | GeometryPort | Optional desktop/web worker later; not a TS domain |
| Bluetooth laser | LaserRangefinderPort | **P0 done (CI fake)** — `BluetoothLaserPort` + `FakeBleLaserTransport` / `ReplayLaserPort`; typed fallback `TypedLaserPort`; `source=laser\|typed`. No real BT in CI |
| vendor SDK depth | DepthStreamPort | **P0 stub + replay** — `VendorSdkDepthAdapter` (primary). Hardware absent in CI; inject `DepthReplayFixture` |
| UVC depth | DepthStreamPort | **P0 stub + replay** — `UvcDepthAdapter`; principle=`uvc_transport` (UVC ≠ depth principle) |
| phone IMU | ImuPort | **P0 stub** — `ModuleImuAdapter` / `PhoneImuAdapter` (degraded) / `MissingImuAdapter` (annotate-only) |
| DXF / PDF / .glb export | Deliverables | **P0 done** — `export_dxf` / `export_pdf` / `export_glb`; mm→m only in glb; StatusGate rejects Fault. Godot 4 sample in `godot/` is read-only |
| EvidencePack | Sidecar | **P0 stub** — attach/detach metadata; may be empty; never SceneIR (I1 / I5) |
| ReleaseTrain | Mapping | **P0 stub** — `core/fixtures/release-train.v1.json` software tag ↔ module SKU / firmware / whitelist file version |
| Android app | Host | **P0 shell** — Gradle + JNI; Fake/Replay in debug; USB/BT permission scaffolding |
| iOS app | Host | **P0 shell** — SwiftUI + ObjC++; typed / Fake loop; no external depth |
| MEP | MepPort | **P1+ stub** — points/polylines placeholder; `NotImplementedMepAdapter` → `NotInP0` (FR-013 / FR-105) |
| soft furnishing | FurnishingLibraryPort | **P1+ stub** — catalog/place; `NotImplementedFurnishingAdapter` → `NotInP0` (FR-013 / FR-106) |
| cloud sync | CloudSyncPort | **P1+ stub** — push/pull document; `NotImplementedCloudSyncAdapter` → `NotInP0` (FR-013 / FR-108) |
| auto quoting | TakeoffQuotePort | **P1+ stub** — `NotImplementedQuoteAdapter` → `NotInP0` (FR-013 / FR-107) |

RF BLE ranging is never a dimension source. P0 Done does **not** require the
P1+ ports above.
