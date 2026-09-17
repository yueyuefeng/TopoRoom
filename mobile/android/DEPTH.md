# Depth SKUs (pluggable) — do not vendor blobs

TopoRoom does **not** lock Gemini E and does **not** vendor Orbbec/OpenNI AAR/JNI
blobs. Depth is `dabai_dcw` | `dual_rgb_uvc` | `fake`. See
[docs/hardware/ADR-001-poc-module-selection.md](../../docs/hardware/ADR-001-poc-module-selection.md).

There is **no evidence** of a ready-made **ASIC depth Type-C** phone accessory
at **~¥200**. Do not claim one.

| SKU | Track | Street class | ASIC depth stream? |
|-----|-------|--------------|--------------------|
| `dabai_dcw` | A | DaBai DCW **~¥788** | Yes (OpenNI / Orbbec SDK **v1**, FW **2460**) |
| `dual_rgb_uvc` | B | Dual RGB UVC **~¥80–200** | **No** — color UVC assist; `depth_fit` low-confidence |
| `fake` | CI | — | Replay |

USB VID for 奥比 products is `0x2BC5`. **PID is not frozen** (do not copy Gemini E `065C`). Record it from the unit.

## Track A — linking OpenNI / Orbbec SDK v1 (DaBai DCW)

1. License: Orbbec OpenNI2 / SDK v1 (DaBai DCW listed, FW 2460). **v2 Android “new design” lists do not replace this** unless you evidence the SKU there.
2. Download from Orbbec’s developer site / GitHub **releases**. Do **not** commit `.aar` / `.so`.
3. Typical Android OpenNI drop-in (local, gitignored): `openni2.3.jar`, `liborbbecusb2.so`, `libOpenNI2*.so`, `assets/openni/*.ini`.
4. Put SDK calls in `mobile/android` JNI **only**, behind a build flag. Domain/C++ ports stay vendor-free. Feed `DepthFrameDTO` into `PluggableDepthAdapter(DabaiDcw, replayOrRealBackend)`.

Until linked, `open()` throws “SDK not linked”.

## Track B — UVC

Use Android `UsbManager` / Camera2-UVC if you must preview. That preview is **not** a depth camera. Laser GATT remains the millimetre path.

## USB filter

`res/xml/usb_device_filter.xml` matches Orbbec VID (any PID) plus a generic device node for UVC dongles. Grant USB Host at runtime. Track A: prefer a **powered hub**.
