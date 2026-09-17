# ADR-001 — China sourcing and the ¥200 budget (PoC tracks)

- **Status:** Accepted for research conclusion; **no single depth SKU is locked**
- **Date:** 2026-09-17 (supersedes the Gemini E lock)
- **Context:** P0 wants a cheap Type-C depth accessory + Bluetooth **laser** (RF BLE ranging is never a ruler) + Android whitelist. The user rejected an imported Gemini E / RealSense pricing narrative and asked for **China-made modules around ¥200 RMB**.

## Decision (dual track — not a Gemini E lock)

There is **no evidence** of a ready-made **ASIC depth** Type-C phone accessory on the open China market at **~¥200**. Claiming that product exists is forbidden until a named SKU, shop listing, and USB identity are attached.

| Track | Depth SKU | Street (CNY, ballpark, not a PO) | What you actually get | When to use |
|-------|-----------|----------------------------------|------------------------|-------------|
| **A — ASIC depth** | **`dabai_dcw`** 奥比中光 DaBai DCW | **~¥788** (Taobao listing class; confirm live quote) | USB **2.0** structured-light camera with on-module ASIC; Android **OpenNI / Orbbec SDK v1** path; FW class **2460**; **no IMU** | Must have a productized depth **stream** on a whitelist phone |
| **B — ¥200 band** | **`dual_rgb_uvc`** (+ laser hub) | Dual-RGB UVC dongle **~¥80–200**; VL53L5CX breakouts **~¥20–80** | **No** on-module depth ASIC. UVC = two color sensors (or one). Tiny ToF = **8×8 zones**, I2C, not a room camera | Stay near ¥200; **laser** is the millimetre source; `depth_fit` is **low-confidence assist only** |
| **CI** | **`fake`** | ¥0 | Replay fixture | Emulator / GoogleTest |

**Always (both tracks):** ESP32 companion hub `toporoom_hub_c3` FW **0.1.0** bridging a JRT M88B / Meskernel LDL-T class **UART laser** onto TopoRoom BLE GATT. Laser (or explicit `typed`) is the critical-edge source.

**ReleaseTrain:** software `0.1.0` ↔ hub FW `0.1.0` ↔ whitelist v1 ↔ **one of** `{dabai_dcw / 2460, dual_rgb_uvc / uvc_host, fake / replay}`.

Gemini E (~**¥1.3k** retail class) and other Orbbec SKUs above DaBai DCW are **out of the cheapest China path**. Orbbec (奥比中光) **is** Shenzhen Chinese; price, not nationality, is why Gemini E is not selected.

## What ¥200 can and cannot buy

Open-market China (Taobao / 立创 / 模块城, 2026 ballpark). Quotes move; this table is **research, not inventory**.

| What shows up near ¥200 | Typical interface | On-module depth ASIC? | Plug Type-C → Android **depth stream**? | Notes |
|-------------------------|-------------------|------------------------|------------------------------------------|-------|
| Dual RGB / “双目 USB” UVC dongle | USB-A, sometimes C pigtail; **UVC color** | **No** | **No** (color/UVC only unless the **phone** runs stereo — not a P0 productized depth camera) | Track B assist |
| Single UVC webcam | USB-A/C | No | No | Useless as depth |
| VL53L5CX / VL53L1X ToF breakout | I2C / UART, not Type-C depth | Tiny ToF **8×8** (or 1-zone) | **No** | Ranging toy / obstacle; not 户型 |
| Unlabelled “3D相机 <¥200” | Mixed | Usually **no**; ask for ASIC + SDK | Do not assume | Reject without datasheet + Android SDK |
| **DaBai DCW** | USB **2.0** (confirm **connector** on the listing: Type-C vs Micro vs pigtail) | **Yes** (奥比 ASIC / OpenNI) | Closest **China** productized path; **not ¥200** | Track A, ~¥788 |
| DaBai / DaBai DW / DCW2 | USB 2.0 | Yes | Same class, often **more** than DCW | Optional if DCW is OOS |
| Gemini E | USB-C USB2 | Yes | Yes on SDK **v1** (FW 3460) | **~¥1.3k** — rejected for this budget |
| Astra Mini S Type-A | USB-A | Yes | Adapter tax | Not ¥200; Type-A is a support tax |
| Intel RealSense | USB-C, import | Yes | Yes | Import narrative rejected |

**Hard statement:** a ¥200 **ready-made ASIC depth Type-C phone accessory** is **not** documented here. Track B must not be marketed as one.

## Track A — DaBai DCW (~¥800) if ASIC depth is mandatory

- Maker: 奥比中光 (Shenzhen). USB 2.0 structured light; official pages: work distance **0.2–2.5 m**, relative precision on the order of **~1% @ 1 m** (not millimetres), avg power **&lt;2.3 W**, **IMU not supported**.
- Host path: Android **OpenNI2** (`openni2.3.jar` + `liborbbec*.so`) or Orbbec SDK **v1**. **Not** assumed on SDK v2 Android “new design” lists. Do not vendor AARs in git (`mobile/android/DEPTH.md`).
- USB: VID **0x2BC5**. PID is **not** frozen here (do not copy Gemini E `065C`). Record `lsusb` / Android UsbDevice on first unit.
- Connector: **confirm the SKU photo**. USB 2.0 ≠ Type-C. If the listing is Micro-B or a board-level pigtail, budget an OTG cable SKU.
- Depth is **layout / fit**, never construction millimetres.

## Track B — ¥200 band: laser + UVC assist

BOM intuition (one kit, ballpark CNY):

| Line | ¥ | Role |
|------|---|------|
| Dual-RGB UVC module | 80–200 | Assist only; `principle=uvc_transport` |
| JRT/Meskernel UART laser | 80–150 | **Critical edges** `source=laser` |
| ESP32-C3 DevKit | 20–50 | GATT hub, not USB video |
| Dupont / 3.3 V | 5–20 | Laser UART |
| **UVC+laser+hub** | **~200–420** | Still **below** DaBai ~788; UVC piece alone can sit in ¥200 |
| Phone | pool | Host IMU (degraded) |

Rules:

- SceneIR key edges: **`laser` or explicit `typed`**. Never silent `depth_fit` as a promised millimetre.
- If Track B writes `depth_fit`, UI **must** show **low confidence** (UVC stereo / sparse ToF is not an ASIC depth camera).
- VL53L5CX is **not** a substitute for a depth dongle.
- RF BLE / RSSI is never a ruler.

## USB roles (both tracks)

```
Whitelist Android phone (USB Host + BLE Central)
  ├─ USB OTG / powered hub ── USB device ── Track A: DaBai DCW
  │                                      or Track B: dual-RGB UVC
  └─ BLE ── TopoRoom hub ESP32 ── UART ── laser (critical mm)
```

The ESP32 does **not** proxy USB video. Powered USB hub is the default for Track A USB2 current; Track B UVC is usually lighter.

## Software mapping

Pluggable `DepthStreamPort` SKU: `dabai_dcw` | `dual_rgb_uvc` | `fake`.
No Gemini E AAR wiring as a PoC gate. Domain stays free of vendor USB/BLE includes.

## Risks

1. **¥200 ≠ ASIC depth.** Saying otherwise is a talk-track fail.
2. **DaBai still USB2 + no IMU + ~1% depth.** Phone IMU degraded; laser remains P0 for keys.
3. **Android whitelist** still required; OpenNI USB Host is picky.
4. **Connector lottery** on China USB2 modules.
5. **OEM UART dialects** on the laser — golden bytes in hub protocol.

## Consequences

- Stage-Gate is **per track** (see `stage-gate-poc-checklist.md`).
- Fail Track A on price → Track B, not “find a mythical ¥200 ASIC Type-C cam”.
- Fail Track B on “must have depth preview like a RealSense” → pay for DaBai DCW, not Gemini E, unless a **cheaper named** China ASIC SKU is evidenced.
