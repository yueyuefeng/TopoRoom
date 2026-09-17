# TopoRoom hub firmware (ESP32)

PlatformIO firmware for **ESP32-C3** (default) or **ESP32-S3**: BLE GATT
laser profile + UART driver for a JRT M88B / Meskernel LDL-T class module.

This MCU is **not** on the USB depth path. Phone OTG (or a powered USB hub)
hosts Track A DaBai DCW or Track B dual-RGB UVC. See [PINOUT.md](./PINOUT.md)
and [PROTOCOL.md](./PROTOCOL.md).

SKU `toporoom_hub_c3` · FW **0.1.0** · ReleaseTrain binds this semver.

## Flash

```bash
cd firmware/toporoom-hub
pio run -e esp32-c3        # build
pio run -e esp32-c3 -t upload
pio device monitor
```

S3: `-e esp32-s3`. Radio-only (no laser wired): `-e esp32-c3-sim`.

Requires [PlatformIO Core](https://platformio.org/install/cli). First build
fetches `espressif32` + NimBLE-Arduino.

## What you should see

1. Serial: `TopoRoom hub 0.1.0 sku=toporoom_hub_c3`
2. nRF Connect: **TopoRoom Hub**, service `a100`, DIS `180A`
3. Write measure golden `01 01 E8 03` → length notify (sim: 1000 mm)

## Files

| Path | Role |
|------|------|
| `include/toporoom_hub_protocol.h` | Packing + UUIDs + JRT frames (shared with C++ tests) |
| `src/main.cpp` | NimBLE GATT, measure loop |
| `src/uart_laser.*` | UART driver |
| `src/bmi270_stub.*` | Future IMU registers (absent in P0) |

## P0 IMU

Hub does **not** expose a body IMU over GATT in 0.1.0. Phone IMU is the
fallback and must stay degraded in the app.
