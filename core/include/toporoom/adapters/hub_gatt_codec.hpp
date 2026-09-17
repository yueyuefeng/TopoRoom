#pragma once

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "toporoom/ports/laser_rangefinder_port.hpp"

namespace toporoom::adapters {

constexpr std::uint8_t kHubOpSingle = 0x01;
constexpr std::uint8_t kHubOpStop = 0x02;
constexpr std::uint8_t kHubFlagRequireLaser = 0x01;
constexpr std::uint8_t kHubStatusOk = 0;
constexpr std::uint8_t kHubSourceInvalid = 0;
constexpr std::uint8_t kHubSourceLaser = 1;
constexpr std::size_t kJrtSingleMeasureSize = 9;

struct HubLengthNotify {
  std::int32_t length_mm = -1;
  std::uint8_t status = 5;
  std::uint8_t source = kHubSourceInvalid;
  std::uint16_t sequence = 0;
  std::uint32_t timestamp_ms = 0;
};

class HubGattCodec {
 public:
  static constexpr std::size_t kCmdSize = 4;
  static constexpr std::size_t kNotifySize = 12;

  static std::array<std::uint8_t, kCmdSize> pack_measure_cmd(
      std::uint8_t opcode = kHubOpSingle, std::uint8_t flags = kHubFlagRequireLaser,
      std::uint16_t timeout_ms = 1000);

  static std::array<std::uint8_t, kNotifySize> pack_length_notify(const HubLengthNotify& n);

  static std::optional<HubLengthNotify> parse_length_notify(const std::uint8_t* data,
                                                            std::size_t len);

  static std::optional<HubLengthNotify> parse_length_notify(
      const std::vector<std::uint8_t>& bytes);

  /* ASCII Fake/Replay ("LEN 900") or 12-byte GATT notify. RF payloads rejected. */
  static ports::MeasureSample parse_laser_payload(const std::string& payload,
                                                  const std::string& device_id);

  static bool is_binary_notify(const std::string& payload);
};

class JrtUartCodec {
 public:
  static std::array<std::uint8_t, kJrtSingleMeasureSize> pack_single_measure();
  static std::optional<std::int32_t> parse_result_mm(const std::uint8_t* data, std::size_t len,
                                                     int scale = 1);
};

}  // namespace toporoom::adapters
