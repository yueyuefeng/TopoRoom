#ifndef TOPOROOM_HUB_PROTOCOL_H
#define TOPOROOM_HUB_PROTOCOL_H

/*
 * Shared TopoRoom hub protocol (C, no ESP / BLE / Orbbec includes).
 *
 * Host GoogleTest and ESP32 firmware both include this header so golden
 * request/response bytes cannot drift. Packing is little-endian on the wire.
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TOPOROOM_HUB_SKU_DEFAULT "toporoom_hub_c3"
#define TOPOROOM_HUB_FW_DEFAULT "0.1.0"
#define TOPOROOM_HUB_ADV_NAME "TopoRoom Hub"

/* 128-bit UUIDs: 0000xxxx-7e90-4c4a-9b1e-746f706f726d ("toporoom") */
#define TOPOROOM_GATT_SERVICE_UUID "0000a100-7e90-4c4a-9b1e-746f706f726d"
#define TOPOROOM_GATT_SKU_UUID "0000a101-7e90-4c4a-9b1e-746f706f726d"
#define TOPOROOM_GATT_FW_UUID "0000a102-7e90-4c4a-9b1e-746f706f726d"
#define TOPOROOM_GATT_MEASURE_CMD_UUID "0000a110-7e90-4c4a-9b1e-746f706f726d"
#define TOPOROOM_GATT_LENGTH_UUID "0000a111-7e90-4c4a-9b1e-746f706f726d"
#define TOPOROOM_GATT_BATTERY_UUID "0000a120-7e90-4c4a-9b1e-746f706f726d"
#define TOPOROOM_GATT_STATUS_UUID "0000a121-7e90-4c4a-9b1e-746f706f726d"

/* Standard Device Information Service (0x180A) — extra for nRF Connect. */
#define TOPOROOM_DIS_UUID "180A"
#define TOPOROOM_DIS_MANUFACTURER_UUID "2A29"
#define TOPOROOM_DIS_MODEL_UUID "2A24"
#define TOPOROOM_DIS_FW_UUID "2A26"

#define TOPOROOM_HUB_MEASURE_CMD_SIZE 4
#define TOPOROOM_HUB_LENGTH_NOTIFY_SIZE 12
#define TOPOROOM_HUB_BATTERY_UNKNOWN 0xFFu

#define TOPOROOM_HUB_OP_SINGLE 0x01u
#define TOPOROOM_HUB_OP_STOP 0x02u

#define TOPOROOM_HUB_FLAG_REQUIRE_LASER 0x01u

#define TOPOROOM_HUB_STATUS_OK 0u
#define TOPOROOM_HUB_STATUS_TIMEOUT 1u
#define TOPOROOM_HUB_STATUS_UART_ERROR 2u
#define TOPOROOM_HUB_STATUS_RF_REJECTED 3u
#define TOPOROOM_HUB_STATUS_BUSY 4u
#define TOPOROOM_HUB_STATUS_BAD_CMD 5u

#define TOPOROOM_HUB_SOURCE_INVALID 0u
#define TOPOROOM_HUB_SOURCE_LASER 1u

/* JRT M88B / Meskernel LDL-T class binary frame (header AA, checksum = sum[1..n-2]). */
#define JRT_FRAME_HEADER 0xAAu
#define JRT_SINGLE_MEASURE_SIZE 9
#define JRT_RESULT_MIN_SIZE 9

static inline int jrt_pack_single_measure(uint8_t out[JRT_SINGLE_MEASURE_SIZE]) {
  static const uint8_t kGolden[JRT_SINGLE_MEASURE_SIZE] = {
      0xAAu, 0x00u, 0x00u, 0x20u, 0x00u, 0x01u, 0x00u, 0x00u, 0x21u};
  if (!out) return -1;
  memcpy(out, kGolden, JRT_SINGLE_MEASURE_SIZE);
  return 0;
}

static inline void toporoom_hub_write_le16(uint8_t* p, uint16_t v) {
  p[0] = (uint8_t)(v & 0xFFu);
  p[1] = (uint8_t)((v >> 8) & 0xFFu);
}

static inline void toporoom_hub_write_le32(uint8_t* p, uint32_t v) {
  p[0] = (uint8_t)(v & 0xFFu);
  p[1] = (uint8_t)((v >> 8) & 0xFFu);
  p[2] = (uint8_t)((v >> 16) & 0xFFu);
  p[3] = (uint8_t)((v >> 24) & 0xFFu);
}

static inline uint16_t toporoom_hub_read_le16(const uint8_t* p) {
  return (uint16_t)((uint16_t)p[0] | ((uint16_t)p[1] << 8));
}

static inline uint32_t toporoom_hub_read_le32(const uint8_t* p) {
  return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) |
         ((uint32_t)p[3] << 24);
}

static inline int toporoom_hub_pack_measure_cmd(uint8_t out[TOPOROOM_HUB_MEASURE_CMD_SIZE],
                                                uint8_t opcode, uint8_t flags,
                                                uint16_t timeout_ms) {
  if (!out) return -1;
  out[0] = opcode;
  out[1] = flags;
  toporoom_hub_write_le16(out + 2, timeout_ms);
  return 0;
}

static inline int toporoom_hub_parse_measure_cmd(const uint8_t* in, size_t len, uint8_t* opcode,
                                                 uint8_t* flags, uint16_t* timeout_ms) {
  if (!in || len < TOPOROOM_HUB_MEASURE_CMD_SIZE || !opcode || !flags || !timeout_ms) {
    return -1;
  }
  *opcode = in[0];
  *flags = in[1];
  *timeout_ms = toporoom_hub_read_le16(in + 2);
  return 0;
}

static inline int toporoom_hub_pack_length_notify(uint8_t out[TOPOROOM_HUB_LENGTH_NOTIFY_SIZE],
                                                  int32_t length_mm, uint8_t status,
                                                  uint8_t source, uint16_t sequence,
                                                  uint32_t timestamp_ms) {
  if (!out) return -1;
  toporoom_hub_write_le32(out, (uint32_t)length_mm);
  out[4] = status;
  out[5] = source;
  toporoom_hub_write_le16(out + 6, sequence);
  toporoom_hub_write_le32(out + 8, timestamp_ms);
  return 0;
}

static inline int toporoom_hub_parse_length_notify(const uint8_t* in, size_t len,
                                                   int32_t* length_mm, uint8_t* status,
                                                   uint8_t* source, uint16_t* sequence,
                                                   uint32_t* timestamp_ms) {
  if (!in || len < TOPOROOM_HUB_LENGTH_NOTIFY_SIZE || !length_mm || !status || !source ||
      !sequence || !timestamp_ms) {
    return -1;
  }
  *length_mm = (int32_t)toporoom_hub_read_le32(in);
  *status = in[4];
  *source = in[5];
  *sequence = toporoom_hub_read_le16(in + 6);
  *timestamp_ms = toporoom_hub_read_le32(in + 8);
  return 0;
}

/* RF / non-laser source is never a dimension. */
static inline int toporoom_hub_length_is_laser_ok(uint8_t status, uint8_t source,
                                                  int32_t length_mm) {
  return status == TOPOROOM_HUB_STATUS_OK && source == TOPOROOM_HUB_SOURCE_LASER &&
         length_mm >= 0;
}

static inline uint8_t jrt_checksum(const uint8_t* frame, size_t len_without_cs) {
  unsigned sum = 0;
  size_t i;
  if (!frame || len_without_cs < 2) return 0;
  for (i = 1; i < len_without_cs; ++i) {
    sum += frame[i];
  }
  return (uint8_t)(sum & 0xFFu);
}

/*
 * Result frame: AA 00 00 22 ERR DH DM DL CS
 * Distance is 24-bit big-endian. Default unit = millimetres (scale=1).
 */
static inline int jrt_parse_result_mm(const uint8_t* in, size_t len, int32_t* length_mm,
                                      uint8_t* err, int scale) {
  uint32_t raw;
  if (!in || !length_mm || !err || len < JRT_RESULT_MIN_SIZE) return -1;
  if (in[0] != JRT_FRAME_HEADER) return -1;
  if (jrt_checksum(in, 8) != in[8]) return -1;
  *err = in[4];
  raw = ((uint32_t)in[5] << 16) | ((uint32_t)in[6] << 8) | (uint32_t)in[7];
  if (scale <= 0) scale = 1;
  *length_mm = (int32_t)(raw / (uint32_t)scale);
  return 0;
}

#ifdef __cplusplus
}
#endif

#endif /* TOPOROOM_HUB_PROTOCOL_H */
