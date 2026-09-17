# Hardware / geometry adapters (later)

These are **not** implemented in this milestone. They will live as C++
adapter libraries that implement ports in `core/include/toporoom/ports`.

| Adapter | Port | Notes |
|---------|------|--------|
| manifold native | GeometryPort | **P0 done** — `ManifoldGeometryPort`: CrossSection → Extrude → Boolean; only adapter that may include manifold (`elalish/manifold` v3.5.3) |
| manifold WASM | GeometryPort | Optional desktop/web worker later; not a TS domain |
| Bluetooth laser | LaserRangefinderPort | **P0 + hub GATT** — `BluetoothLaserPort` + `HubGattCodec` (golden bytes) + `FakeBleLaserTransport` / `ReplayLaserPort`; Android `TopoRoomHubBleClient` talks to ESP32 hub. Typed fallback `TypedLaserPort`. RF ranging is never a ruler |
| vendor SDK depth | DepthStreamPort | **`OrbbecGeminiEDepthAdapter`** (SKU `orbbec_gemini_e`, FW 3460, VID 2BC5 PID 065C). CI: replay fixture. Official Orbbec AAR via `mobile/android/ORBBEC.md` — not vendored |
| UVC depth | DepthStreamPort | **Stub** — `OrbbecGeminiEUvcStub` / `UvcDepthAdapter`; principle=`uvc_transport`. Not a Stage-Gate pass |
| phone IMU | ImuPort | **P0** — `PhoneImuAdapter` (degraded). Gemini E has no module IMU. Hub BMI270 is a register stub |
| DXF / PDF / .glb export | Deliverables | **P0 done** — `export_dxf` / `export_pdf` / `export_glb`; mm→m only in glb; StatusGate rejects Fault. Godot 4 sample in `godot/` is read-only |
| EvidencePack | Sidecar | **P0 stub** — attach/detach metadata; may be empty; never SceneIR (I1 / I5) |
| ReleaseTrain | Mapping | software `0.1.0` ↔ `orbbec_gemini_e` 3460 ↔ hub FW `0.1.0` ↔ whitelist v1 |
| Android app | Host | Gradle + JNI; Fake/Replay in debug; BLE hub client + USB Gemini E filter |
| iOS app | Host | **P0 shell** — SwiftUI + ObjC++; typed / Fake loop; no external depth |
| MEP | MepPort | **P1+ stub** — points/polylines placeholder; `NotImplementedMepAdapter` → `NotInP0` (FR-013 / FR-105) |
| soft furnishing | FurnishingLibraryPort | **P1+ stub** — catalog/place; `NotImplementedFurnishingAdapter` → `NotInP0` (FR-013 / FR-106) |
| cloud sync | CloudSyncPort | **P1+ stub** — push/pull document; `NotImplementedCloudSyncAdapter` → `NotInP0` (FR-013 / FR-108) |
| auto quoting | TakeoffQuotePort | **P1+ stub** — `NotImplementedQuoteAdapter` → `NotInP0` (FR-013 / FR-107) |
| HostedComponent | Domain | **P0 model / not a Done gate** — beam/column/flue; SceneIR optional array |

RF BLE ranging is never a dimension source. P0 Done does **not** require the
P1+ ports above. P0 drawing type is **户型图** (not 平面布置图).
