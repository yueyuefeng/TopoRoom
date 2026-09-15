# Hardware adapters (stubbed)

P0 software core uses ports + fakes. These adapters are **not implemented** yet.

| Package | Port | Status |
|---------|------|--------|
| `adapter-depth-vendorsdk` | `DepthStreamPort` | TODO — Vendor SDK primary |
| `adapter-depth-uvc` | `DepthStreamPort` | TODO — UVC transport shell (not a depth principle) |
| `adapter-laser-bt` | `LaserRangefinderPort` | TODO — Bluetooth transport only; source=`laser` |
| `adapter-imu-phone` | ImuPort | TODO — phone IMU fallback with degradation flag |
| `adapter-store-indexeddb` | `DocumentStorePort` | TODO — local SceneIR persistence |
| `adapter-export-dxf` | Deliverables | TODO — semantic DXF |

RF BLE ranging is **never** a dimension source.
