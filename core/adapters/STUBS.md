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

RF BLE ranging is never a dimension source.
