# TopoRoom hub GATT + UART protocol

Firmware and host adapters share `include/toporoom_hub_protocol.h`.
GoogleTest (`core/tests/hub_protocol_test.cpp`) locks the golden bytes below.

RF BLE ranging is **never** a length. `source` must be `1` (laser) or the
host rejects the notify.

## Advertising

- Name: `TopoRoom Hub`
- Service UUID: `0000a100-7e90-4c4a-9b1e-746f706f726d`

## Custom service `a100`

| Char | UUID | Props | Payload |
|------|------|-------|---------|
| SKU | `a101` | Read | UTF-8 `toporoom_hub_c3` |
| FW semver | `a102` | Read | UTF-8 `0.1.0` |
| Measure command | `a110` | Write | 4 bytes LE |
| Length notify | `a111` | Notify | 12 bytes LE |
| Battery | `a120` | Read / Notify | 1 byte percent; `0xFF` = unknown |
| Hub status | `a121` | Read | 1 byte (`0` idle/ok) |

Also advertised: standard **Device Information** `180A` (manufacturer TopoRoom,
model = SKU, firmware revision = semver).

### Measure command (4 bytes)

| Offset | Type | Field |
|--------|------|-------|
| 0 | u8 | opcode `0x01` single, `0x02` stop |
| 1 | u8 | flags: bit0 **must** be 1 (`REQUIRE_LASER`) |
| 2–3 | u16 LE | timeout ms (`0` → firmware default 1000) |

Golden single-shot, 1000 ms:

```
01 01 E8 03
```

If bit0 is clear, firmware notifies `status=RF_REJECTED` and `source=0`.

### Length notify (12 bytes)

| Offset | Type | Field |
|--------|------|-------|
| 0–3 | i32 LE | `length_mm` (negative = invalid) |
| 4 | u8 | status: 0 ok, 1 timeout, 2 UART, 3 RF rejected, 4 busy, 5 bad cmd |
| 5 | u8 | source: **1 = laser only valid dimension** |
| 6–7 | u16 LE | sequence |
| 8–11 | u32 LE | `timestamp_ms` (hub millis) |

Golden 900 mm laser, seq 1, ts 0:

```
84 03 00 00  00 01  01 00  00 00 00 00
```

Host `BluetoothLaserPort` accepts this binary **or** ASCII `LEN 900` (Fake/Replay).

## UART laser (JRT / Meskernel)

Baud default **19200 8N1**. Checksum = sum of bytes `[1 .. n-2]` (header `AA` excluded).

Golden **single measure** request (9 bytes):

```
AA 00 00 20 00 01 00 00 21
```

Golden **result** 900 mm (`ERR=0`, distance `00 03 84`, CS `A9`):

```
AA 00 00 22 00 00 03 84 A9
```

`esp32-c3-sim` skips UART and notifies 1000 mm laser so GATT can be checked
without a module.

## nRF Connect smoke

1. Flash `pio run -e esp32-c3-sim -t upload`
2. Connect **TopoRoom Hub**
3. Enable notify on `a111`
4. Write `01 01 E8 03` to `a110`
5. Expect 12-byte notify, `source` byte = `01`
