# Stage-Gate PoC checklist — dual track (DaBai DCW **or** ¥200 laser+UVC)

See [ADR-001](./ADR-001-poc-module-selection.md). **No Gemini E lock.**  
**Fail a hardware gate → change SKU / phone / track; do not open moulds.**

Software tag: **0.1.0**  
Hub (both tracks): **`toporoom_hub_c3` FW 0.1.0**  
Whitelist: `core/fixtures/android-whitelist.v1.json`

Pick **one** depth track before the review:

| Track | `moduleSku` | Firmware token | ASIC depth stream? |
|-------|-------------|----------------|--------------------|
| **A** | `dabai_dcw` | `2460` | Yes (OpenNI / SDK v1) |
| **B** | `dual_rgb_uvc` | `uvc_host` | **No** — UVC assist only |
| CI | `fake` | `replay` | Replay |

Do **not** claim a ¥200 Type-C ASIC depth accessory. Depth is never millimetre-everywhere; **laser** (or explicit `typed`) is the critical-edge source.

CI Fake/Replay is **necessary** and **not sufficient** for a hardware Go.

## Gate 0 — Identity (both tracks)

- [ ] App loads whitelist v1 + ReleaseTrain; listed combo matches **this** track’s SKU/FW + hub `0.1.0`.
- [ ] Unlisted phone is experimental / Fake in debug, never “certified”.
- [ ] Hub GATT: name **TopoRoom Hub**, SKU `toporoom_hub_c3`, semver `0.1.0`.
- [ ] Operator can still complete guided capture with **Fake laser** on emulator.

## Gate L — Hub GATT + laser (both tracks — this is the millimetre gate)

RF / RSSI fail.

- [ ] Flash `firmware/toporoom-hub` (`esp32-c3` or `esp32-c3-sim`).
- [ ] nRF Connect: service `a100`; write `01 01 E8 03`; length notify `source=laser`.
- [ ] App: two guided keys with `source=laser` and `instrumentId=toporoom_hub_c3` (or Fake in CI).

## Track A gates — DaBai DCW (~¥800 ASIC)

VendorSdk / OpenNI path. Dual-RGB UVC does **not** pass Track A.

### A1 Kit

- [ ] Module is a named **DaBai DCW** (or recorded substitute DaBai DW/DCW2 with quote). Street class **~¥788**, **not ¥200**.
- [ ] USB VID **2BC5**; PID recorded from the unit (not assumed `065C`).
- [ ] Connector recorded (Type-C / Micro / pigtail). Cable SKU recorded.
- [ ] Camera FW class **2460** (or the number the SDK reports) written into session meta.

### A2 Power / OTG

| Phone | `hubSku=none` | `hubSku=powered_hub_a` | Result |
|-------|---------------|------------------------|--------|
| Pixel 8 / API 34 | | | |
| SM-S911B / API 33 | | | |
| 2201123G / API 33 | | | |

- [ ] Brown-out / USB drop notes. Default assumption: **powered hub**.

### A3 Stream (≥30 min)

- [ ] Official OpenNI/Orbbec bits linked per `mobile/android/DEPTH.md` (not committed blobs).
- [ ] Depth **preview** starts; unplug surfaces a transport error.
- [ ] **≥30 min** continuous stream on **≥1** whitelist phone.
- [ ] Operator does **not** treat depth picks as construction mm.

If the SDK is not linked, Track A is **open**. Hub/GATT work can proceed.

### A4 Guided + export

- [ ] Guided room; **≥2** `source=laser` (or explicit typed) keys; ≥1 opening; rebuild.
- [ ] DXF+PDF; `.glb` only if Status OK.

## Track B gates — ¥200 band (laser + UVC assist)

Passing Track B is **not** passing Track A. Do not write “we have a depth camera” in the Go memo.

### B1 Kit (stay honest about ¥)

- [ ] Dual-RGB (or single) **UVC** module street price recorded (**~¥80–200**).
- [ ] Laser+hub prices recorded. Combined kit may be **~¥200–420**; still call UVC the ¥200 **camera** line, not an ASIC depth dongle.
- [ ] No VL53L5CX claimed as room depth.

### B2 UVC assist (optional for Go, required if SKU is `dual_rgb_uvc`)

- [ ] Android sees a UVC device (USB Host permission).
- [ ] Preview is **color** (or dual color). App labels it **not ASIC depth**.
- [ ] Any `depth_fit` measurement is **low-confidence** in UI; must not overwrite `laser`/`typed`.
- [ ] 30-minute **UVC color** preview may be recorded as a power/USB note; it does **not** replace Track A’s depth-stream gate.

### B3 Guided + export (this **is** the Track B product gate)

- [ ] Guided room on whitelist or debug-Fake host.
- [ ] **≥2 laser** keys (hub GATT or Fake in lab with a recorded exception).
- [ ] DXF+PDF; `.glb` if Status OK.
- [ ] SceneIR shows laser/typed; `depth_fit` if present is visibly low-confidence.

## Gate I — IMU

- [ ] Phone IMU; degraded label. Hub BMI270 stub is not a body IMU.

## Gate P — Paperwork

- [ ] Track letter **A or B** on the cover.
- [ ] Quotes / screenshots for the camera line (¥788 vs ¥200 class).
- [ ] Problem list. **Go / No-Go** per track.
- [ ] No-Go on “need ASIC depth at ¥200” → **Track A**, not a fictional SKU.

## Talk-track red lines

- No “¥200 Type-C ASIC depth phone dongle” without a named listing.
- No “Gemini E locked”.
- No millimetre-everywhere depth.
- Laser (or explicit typed) for critical edges.
- Supported phones = whitelist only.
