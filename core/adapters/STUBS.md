# Hardware / geometry adapters (later)

These are **not** implemented in this milestone. They will live as C++
adapter libraries that implement ports in `core/include/toporoom/ports`.

| Adapter | Port | Notes |
|---------|------|--------|
| manifold native | GeometryPort | CrossSection → Extrude → Boolean; only place that may include manifold |
| manifold WASM | GeometryPort | Optional desktop/web worker later; not a TS domain |
| vendor SDK depth | DepthStreamPort | Android NDK primary |
| UVC depth | DepthStreamPort | Transport shell, not a depth principle |
| Bluetooth laser | LaserRangefinderPort | BT is transport; `source=laser` |
| typed laser | LaserRangefinderPort | Keyboard fallback; `source=typed` |
| phone IMU | ImuPort | Degradation flag required |
| DXF export | Deliverables | Reads SceneIR, not triangle mesh |

RF BLE ranging is never a dimension source.
