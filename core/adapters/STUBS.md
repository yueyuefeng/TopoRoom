# Hardware / geometry adapters (later)

These are **not** implemented in this milestone. They will live as C++
adapter libraries that implement ports in `core/include/toporoom/ports`.

| Adapter | Port | Notes |
|---------|------|--------|
| manifold native | GeometryPort | **P0 done** — `ManifoldGeometryPort`: CrossSection → Extrude → Boolean; only adapter that may include manifold (`elalish/manifold` v3.5.3) |
| manifold WASM | GeometryPort | Optional desktop/web worker later; not a TS domain |
| Bluetooth laser | LaserRangefinderPort | **P0 + hub GATT** — `BluetoothLaserPort` + `HubGattCodec` + Fake/Replay; Android `TopoRoomHubBleClient`. RF ranging is never a ruler |
| vendor SDK depth | DepthStreamPort | **Pluggable** `dabai_dcw` \| `dual_rgb_uvc` \| `fake`. Track A = DaBai DCW (~¥788 ASIC). Track B = UVC assist, not ASIC depth. No Gemini E lock; blobs not vendored (`mobile/android/DEPTH.md`) |
| UVC depth | DepthStreamPort | `dual_rgb_uvc` / `UvcDepthAdapter`; principle=`uvc_transport`. Not a Track A pass |
| phone IMU | ImuPort | **P0** — `PhoneImuAdapter` (degraded). DaBai DCW has no module IMU. Hub BMI270 stub |
| DXF / PDF / .glb export | Deliverables | **P0 done** |
| EvidencePack | Sidecar | **P0 stub** |
| ReleaseTrain | Mapping | software `0.1.0` ↔ hub FW `0.1.0` ↔ whitelist v1 ↔ tracks `{dabai_dcw, dual_rgb_uvc, fake}` |
| Android app | Host | Gradle + JNI; Fake/Replay; BLE hub client |
| iOS app | Host | **P0 shell** — no external depth |
| MEP / furnishing / cloud / quote | P1+ | stubs → `NotInP0` |
| HostedComponent | Domain | beam/column/flue |

RF BLE ranging is never a dimension source. P0 Done does **not** require the
P1+ ports above. P0 drawing type is **户型图** (not 平面布置图).
