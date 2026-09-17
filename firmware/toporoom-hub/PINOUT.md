# TopoRoom hub pinout

The ESP32 is a **BLE + UART companion**. It does **not** carry phone USB
video. Plug Track A (DaBai DCW) or Track B (dual-RGB UVC) into the **phone**
(OTG) or a **powered USB hub**.

Laser UART is 3.3 V TTL. Confirm the OEM module voltage before wiring 5 V.

## ESP32-C3 DevKitM-1 (`env:esp32-c3`)

| Function | GPIO | Direction | Notes |
|----------|------|-----------|-------|
| Laser UART TX (hub → module RX) | **4** | out | `LASER_UART_TX_PIN` |
| Laser UART RX (hub ← module TX) | **5** | in | `LASER_UART_RX_PIN` |
| Laser EN / MOSFET gate | **6** | out | Active high; optional. Leave unconnected if the module is always on. |
| I2C SDA (BMI270 stub) | **8** | i2c | P0 unused; future IMU |
| I2C SCL (BMI270 stub) | **9** | i2c | |
| USB-CDC serial | USB | debug | Logs only. **Not** the depth camera. |

Default baud: **19200 8N1** (`LASER_UART_BAUD`). Meskernel sheets also list 115200 — override in `platformio.ini`.

## ESP32-S3 DevKitC-1 (`env:esp32-s3`)

| Function | GPIO |
|----------|------|
| Laser UART TX | **17** |
| Laser UART RX | **18** |
| Laser EN | **6** |
| I2C SDA / SCL | **8** / **9** |

## JRT M88B / Meskernel LDL-T class

Typical 4-pin: `VCC` 3.3 V, `GND`, `TX`, `RX`. Cross TX/RX with the ESP32.
Do not connect USB-UART 5 V adapters to the module VCC.

Distance scale: `LASER_DIST_SCALE` (default **1** = millimetres). Some OEM
firmwares report 0.1 mm; set scale to `10` if golden UART frames look 10× high.

## Phone-side USB (not this MCU)

| Item | Track A DaBai DCW | Track B dual RGB UVC |
|------|-------------------|----------------------|
| Role | Phone = USB **Host**; camera = **Device** | Same |
| VID | Orbbec `0x2BC5` (PID: record on unit) | Vendor-specific UVC |
| Power | USB 2.0, ~2.3 W class; prefer **powered hub** | Usually lighter |

## BMI270 stub (future)

| Register | Addr | P0 behaviour |
|----------|------|----------------|
| `CHIP_ID` | `0x00` | Expected `0x24` if populated; stub returns **not present** |
| `PWR_CTRL` | `0x7D` | Not driven in P0 |
| `CMD` | `0x7E` | Not driven in P0 |

P0 gravity align uses the **phone IMU** and must stay labelled degraded.
