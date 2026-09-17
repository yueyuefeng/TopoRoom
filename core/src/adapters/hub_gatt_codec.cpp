#include "toporoom/adapters/hub_gatt_codec.hpp"

#include <stdexcept>
#include <string>
#include <vector>

#include "toporoom/adapters/capture_transport_error.hpp"

#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
#endif
#include "toporoom_hub_protocol.h"
#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

namespace toporoom::adapters {
namespace {

[[noreturn]] void protocol_fail(const char* msg) {
  throw CaptureTransportError(CaptureTransportError::Kind::Protocol, msg);
}

}  // namespace

std::array<uint8_t, HubGattCodec::kCmdSize> HubGattCodec::pack_measure_cmd(
    uint8_t opcode, uint8_t flags, uint16_t timeout_ms) {
  std::array<uint8_t, kCmdSize> out{};
  toporoom_hub_pack_measure_cmd(out.data(), opcode, flags, timeout_ms);
  return out;
}

std::array<uint8_t, HubGattCodec::kNotifySize> HubGattCodec::pack_length_notify(
    const HubLengthNotify& n) {
  std::array<uint8_t, kNotifySize> out{};
  toporoom_hub_pack_length_notify(out.data(), n.length_mm, n.status, n.source, n.sequence,
                                  n.timestamp_ms);
  return out;
}

std::optional<HubLengthNotify> HubGattCodec::parse_length_notify(const uint8_t* data,
                                                                 std::size_t len) {
  HubLengthNotify n;
  if (toporoom_hub_parse_length_notify(data, len, &n.length_mm, &n.status, &n.source,
                                       &n.sequence, &n.timestamp_ms) != 0) {
    return std::nullopt;
  }
  return n;
}

std::optional<HubLengthNotify> HubGattCodec::parse_length_notify(
    const std::vector<uint8_t>& bytes) {
  return parse_length_notify(bytes.data(), bytes.size());
}

bool HubGattCodec::is_binary_notify(const std::string& payload) {
  return payload.size() == kNotifySize;
}

ports::MeasureSample HubGattCodec::parse_laser_payload(const std::string& payload,
                                                       const std::string& device_id) {
  if (payload.rfind("RF", 0) == 0) {
    protocol_fail("rf_ble is never a dimension source");
  }
  if (is_binary_notify(payload)) {
    const auto parsed = parse_length_notify(
        reinterpret_cast<const uint8_t*>(payload.data()), payload.size());
    if (!parsed) protocol_fail("unparseable hub length notify");
    if (parsed->source != kHubSourceLaser) {
      protocol_fail("rf_ble is never a dimension source");
    }
    if (!toporoom_hub_length_is_laser_ok(parsed->status, parsed->source, parsed->length_mm)) {
      protocol_fail("hub laser notify not ok");
    }
    ports::MeasureSample sample;
    sample.value_mm = static_cast<double>(parsed->length_mm);
    sample.timestamp = parsed->timestamp_ms == 0 ? 1 : parsed->timestamp_ms;
    sample.source = "laser";
    sample.instrument_id = device_id;
    return sample;
  }

  std::string number = payload;
  if (payload.rfind("LEN ", 0) == 0) number = payload.substr(4);
  ports::MeasureSample sample;
  try {
    sample.value_mm = std::stod(number);
  } catch (const std::exception&) {
    protocol_fail("unparseable laser payload");
  }
  sample.timestamp = 1;
  sample.source = "laser";
  sample.instrument_id = device_id;
  return sample;
}

std::array<uint8_t, kJrtSingleMeasureSize> JrtUartCodec::pack_single_measure() {
  std::array<uint8_t, kJrtSingleMeasureSize> out{};
  jrt_pack_single_measure(out.data());
  return out;
}

std::optional<int32_t> JrtUartCodec::parse_result_mm(const uint8_t* data, std::size_t len,
                                                     int scale) {
  int32_t mm = -1;
  uint8_t err = 0;
  if (jrt_parse_result_mm(data, len, &mm, &err, scale) != 0) return std::nullopt;
  if (err != 0) return std::nullopt;
  return mm;
}

}  // namespace toporoom::adapters
