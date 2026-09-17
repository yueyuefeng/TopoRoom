# Stage-Gate PoC checklist — Gemini E + TopoRoom hub

Locked SKUs: see [ADR-001](./ADR-001-poc-module-selection.md). **Fail any hardware gate → change SKU / phone; do not open moulds** (NFR-007).

Software tag under test: **0.1.0**  
Depth: **`orbbec_gemini_e` FW 3460** (VID `0x2BC5` PID `0x065C`)  
Companion hub: **`toporoom_hub_c3` FW 0.1.0**  
Whitelist file: `core/fixtures/android-whitelist.v1.json` (copied to the Android app assets)

## What this gate is (and is not)

| In | Out |
|----|-----|
| ≥30 min depth **preview stream** on a **listed** phone | “Depth is millimetre-accurate everywhere” |
| Guided one-room capture | Custom enclosure / certification |
| **≥2** SceneIR key edges with `source=laser` (or explicit `typed`) | RF BLE proximity as a ruler |
| Export DXF + PDF; `.glb` only if Status is OK | iOS external depth |
| Documented OTG vs powered-hub behaviour | EVT tooling |

CI Fake/Replay passing is **necessary** and **not sufficient** for this gate.

## Gate A — Kit + identity

- [ ] Gemini E enumerates as USB device on the phone (`dmesg` / Android USB Host: VID **2BC5** PID **065C**).
- [ ] App loads whitelist v1 + ReleaseTrain; listed phone shows **Host on Android whitelist** (not Fake/Replay banner).
- [ ] `ReleaseTrain` matches: software `0.1.0` + `orbbec_gemini_e` + FW `3460` + hub FW `0.1.0` + whitelist version `1`.
- [ ] Unlisted phone is **experimental / Fake** in debug, never advertised as certified.
- [ ] Hub firmware reports SKU `toporoom_hub_c3` and semver `0.1.0` over GATT (nRF Connect or app).

## Gate B — Power / OTG (USB2)

Record **phone model, API, cable, hub SKU** for each row. Naked OTG is allowed only if it survives Gate C.

| Phone (example whitelist) | `hubSku=none` (naked OTG) | `hubSku=powered_hub_a` | Result |
|---------------------------|---------------------------|-------------------------|--------|
| Pixel 8 / API 34 | | | |
| SM-S911B (Galaxy S23) / API 33 | | | |
| 2201123G (Xiaomi 12) / API 33 | | | |

Notes to capture:

- [ ] Brown-out, thermal throttle, or USB disconnect during stream.
- [ ] Whether a **powered hub** is mandatory (default assumption: **yes**).
- [ ] Cable length / C-C vs hub C-A. Do not mix unlisted cables into a “pass”.

## Gate C — Depth stream (≥30 min)

VendorSdk path only for pass/fail. UVC stub does **not** count.

- [ ] Official Orbbec Android AAR linked per `mobile/android/ORBBEC.md` (not a random blob in git).
- [ ] Depth preview starts; disconnect surfaces a transport error (not a silent freeze).
- [ ] **Continuous stream ≥ 30 minutes** on **at least one** whitelist phone without process death or USB drop.
- [ ] Firmware string read from the device is recorded (expect **3460** class).
- [ ] Operator does **not** treat depth point-picks as construction millimetres.

If the AAR is not yet linked, this gate is **open**. Firmware/GATT work can proceed; **PoC is not closed**.

## Gate D — Hub GATT + laser (critical edges)

RF / RSSI / iBeacon-style ranging is an automatic fail.

- [ ] Flash `firmware/toporoom-hub` (PlatformIO `esp32-c3` or `esp32-s3`).
- [ ] nRF Connect (or equivalent) sees:
  - Device name **TopoRoom Hub**
  - Service `0000a100-7e90-4c4a-9b1e-746f706f726d`
  - Device Information Service (`180A`) SKU/FW
  - Length characteristic **Notify**
- [ ] Write measure command golden bytes `01 01 E8 03` → notify `length_mm` with `source=laser`.
- [ ] UART laser (or `esp32-c3-sim` for radio-only bring-up) never labels RF as length.
- [ ] App **Fake laser still works** on emulator/debug without a hub.
- [ ] On a real hub: two guided key edges written with `source=laser` and `instrumentId` = hub SKU.

## Gate E — Guided room + export

- [ ] Guided session: walls → **≥2 laser (or explicit typed)** keys → ≥1 opening → rebuild.
- [ ] SceneIR measurements show `laser` (preferred) or `typed` with the explicit flag.
- [ ] Export **DXF + PDF** always when generated.
- [ ] **`.glb` only when Status is OK**; Fault rejects structural solid.
- [ ] Godot 4 can open the `.glb` (read-only). Optional if the operator has Godot; not a firmware fail.

## Gate F — IMU degrade labelling

- [ ] P0 uses **phone IMU**; UI/log mentions module IMU missing / degraded.
- [ ] Hub BMI270 stub does not pretend to be a calibrated body IMU.

## Gate G — Paperwork to close PoC

- [ ] Filled table in Gate B (3 phones × hub/no-hub as required by FINAL §7.2).
- [ ] Problem list (USB drops, SDK crashes, UART dialects) with owner.
- [ ] This checklist signed with software tag, camera FW, hub FW, whitelist file version.
- [ ] **Go / No-Go:** No-Go means **another SKU or phone**, not tooling.

## Operator script (happy path)

1. Powered USB hub → phone Host port; Gemini E on a hub downstream port; hub self-powered.
2. Flash ESP32; laser UART 3.3 V; EN GPIO as in `firmware/toporoom-hub/PINOUT.md`.
3. Install debug or release APK; grant USB Host + Bluetooth.
4. Confirm whitelist host-OK; connect **TopoRoom Hub**; take two laser keys on a rectangular room.
5. Start depth preview; leave streaming **30 min** while filling the power table.
6. Finish guided capture; export; attach logs + SceneIR JSON to the evidence folder (EvidencePack may stay empty).

## Talk-track red lines (repeat at the review)

- Depth is for **layout / fit**, not promised millimetres.
- Laser (or explicit typed) is the **critical-edge** source.
- Supported phones = **published whitelist only**.
