# ADR-001 — PoC module selection (cheapest P0-compliant path)

- **Status:** Accepted (locked for Stage-Gate PoC)
- **Date:** 2026-09-17
- **Context:** FINAL hardware spec requires an off-the-shelf Type-C depth module + Bluetooth **laser** (RF BLE ranging is never a ruler) + Android whitelist. User selected the **cheapest P0-compliant** kit. This ADR freezes SKUs so software `ReleaseTrain` and hub firmware can bind.

## Decision

| Role | Locked SKU | Why |
|------|------------|-----|
| Depth | **Orbbec Gemini E** (`orbbec_gemini_e`) | Cheapest **USB-C** module with an official Android SDK path (Orbbec SDK v1 / OpenNI wrapper, camera FW **3460**). Phone is USB **host** (OTG); Gemini E is the USB **device**. |
| Laser | **JRT M88B / Meskernel LDL-T class** UART OEM module, bridged by **TopoRoom hub** | Time-of-flight **laser** millimetres, not RF proximity. Cheap UART modules have no stable public BLE GATT; the ESP32 hub owns the TopoRoom GATT profile. |
| Companion hub | **ESP32-C3** (S3 alt) `toporoom_hub_c3` FW **0.1.0** | BLE GATT + UART laser (+ BMI270 register stub). **Not** a USB hub and **not** on the Gemini E data path. |
| IMU | **Phone IMU** (P0) | Gemini E has **no** onboard IMU. Hub may stub BMI270 later. UI must mark degrade. |
| Depth adapter | **VendorSdk primary** (`OrbbecGeminiEDepthAdapter`) | UVC is a **transport stub only** if a later firmware exposes it. UVC ≠ depth principle. |

**ReleaseTrain bind:** software tag `0.1.0` ↔ `orbbec_gemini_e` FW `3460` ↔ hub FW `0.1.0` ↔ `android-whitelist.v1.json`.

## Alternatives considered

| Option | Interface | Onboard IMU | Android SDK | Street BOM (CNY, **ballpark** 2026, not a quote) | Why not P0-cheapest |
|--------|-----------|-------------|-------------|----------------------|---------------------|
| **Gemini E (locked)** | USB-C, **USB 2.0**, ~2.3 W avg / <5 W peak | **No** | Orbbec SDK **v1** (Gemini E listed, FW 3460). **Not** on Orbbec SDK v2 Android support matrix. | Module **~800–2500** | Selected. |
| Astra Mini S Type-A | USB-**A**; needs OTG adapter / gender + extra cable SKU | No | Legacy OpenNI; Type-A on modern phones is a whitelist and mechanical failure magnet | Module **~400–1200** + adapter | Headline cheaper, **not cheaper in system cost** (adapter, support, USB-A host quirks). Type-A is a PoC tax. |
| Astra 2 | USB-C, USB 3 capable | **Yes** | SDK v1 + v2 “recommended for new designs” | Module **~2500–5000** | Better IMU/USB3 headroom; **over the cheapest-P0 budget**. Revisit if Gemini E fails Stage-Gate power/SDK. |

Laser alternatives:

| Option | Notes |
|--------|--------|
| Consumer BLE laser (Bosch / Mileseey / similar) | Often **closed** GATT; pairing UX varies; RF-looking “measure” apps must not be confused with laser. Higher unit cost. |
| UART OEM (JRT M88B / Meskernel LDL-T) + ESP32 GATT | **Locked.** We own the profile, golden bytes, and `source=laser` path. ~80–250 CNY module + ~20–50 CNY MCU. |
| Phone AR / depth-only edges | Forbidden as critical-edge millimetres (NFR-003 / talk-track red line). |

## BOM ballpark (PoC kit, not a purchase order)

Amounts are order-of-magnitude **CNY** for one engineering kit. Confirm with a quote before EVT.

| Line | Qty | Ballpark CNY | Notes |
|------|-----|--------------|-------|
| Orbbec Gemini E (USB-C dongle/module) | 1 | 800–2500 | USB 2.0; no IMU |
| JRT M88B or Meskernel LDL-T UART laser | 1 | 80–250 | Class 2; do not stare into beam |
| ESP32-C3 DevKit (or S3) | 1 | 20–50 | Companion hub only |
| Powered USB **2.0/3.0** hub + short C-C / C-A cable | 1 | 40–150 | Treat as **default** for ≥30 min stream |
| Dupont / 3.3 V level to laser UART | 1 | 5–20 | Laser is usually 3.3 V TTL; check OEM sheet |
| Whitelist Android phones (Pixel 8, Galaxy S23, Xiaomi 12, …) | 3 | pool | Host; not in accessory BOM |
| **Kit total (accessories)** | | **~1000–3000** | vs Astra 2 kit **~3000–6000+** |

Open-mould enclosure, certification, and custom flex are **out of PoC**. Fail Stage-Gate → change SKU; **do not tool**.

## USB roles (do not confuse the two “hubs”)

```
Whitelist Android phone (USB Host + BLE Central)
  ├─ USB OTG / powered USB hub ── USB-C ── Gemini E  (USB Device, VID 2BC5 PID 065C)
  └─ BLE ── TopoRoom hub ESP32 ── UART ── JRT/Meskernel laser
                 │
                 └─ optional I2C BMI270 (stub; P0 unused)
```

- **Gemini E** enumerates on the **phone**. The ESP32 does **not** proxy USB video.
- **Powered USB hub** = current budget for USB2 depth. Separate SKU (`powered_hub_a` vs `none` for phones that survive naked OTG).
- **TopoRoom hub** = BLE identity + laser millimetres. Firmware stays BLE+UART.

## Risks (accepted for PoC)

1. **No onboard IMU.** Gravity align is **phone IMU**, marked degraded. Hub BMI270 is a register stub only.
2. **USB 2.0 power.** ~2.3 W average on a phone OTG port browns out, throttles, or drops the camera. Default fixture is a **powered hub**. `hubSku=none` is only for phones that pass the 30-minute gate without it.
3. **Android whitelist.** Gemini E is on **SDK v1** (min FW 3460), not the v2 Android “new design” list. Some Android 10 images need the historic `targetSdk 27` USB-camera workaround — document per phone, do not claim “any USB-C phone”.
4. **Depth is not a millimetre ruler.** Vendor precision is on the order of **~1% at 1 m** (and worse at 2 m), range **0.2–2.5 m**. Critical edges **must** be laser (or explicit `typed`). Do not market “mm everywhere”.
5. **UVC secondary is a stub.** Do not assume Gemini E exposes a stable UVC depth stream; VendorSdk is the only PoC path.
6. **OEM UART dialects.** JRT/Meskernel frames are documented with golden bytes; baud and distance scale are compile-time. A different OEM firmware can still speak “almost” the same frame — PoC must log raw UART on first bring-up.
7. **Laser safety.** Class 2 handheld; never treat RF RSSI as length.

## Consequences

- Adapters: `OrbbecGeminiEDepthAdapter` (VendorSdk skeleton + JNI stubs, no vendored proprietary AAR) and `BluetoothLaserPort` / Android `TopoRoomHubBleClient` targeting the TopoRoom GATT profile.
- Domain stays free of Orbbec and BLE includes.
- Fake/Replay laser and depth remain for CI and emulator.
- If Stage-Gate fails on SDK/power, the fallback SKU to evaluate is **Astra 2** (not Mini S Type-A).
