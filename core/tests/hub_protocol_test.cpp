#include <array>
#include <cstdint>
#include <string>
#include <vector>

#include <gtest/gtest.h>

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/hub_gatt_codec.hpp"
#include "toporoom/adapters/laser_adapters.hpp"

using toporoom::adapters::BluetoothLaserPort;
using toporoom::adapters::CaptureTransportError;
using toporoom::adapters::FakeBleLaserTransport;
using toporoom::adapters::HubGattCodec;
using toporoom::adapters::HubLengthNotify;
using toporoom::adapters::JrtUartCodec;
using toporoom::adapters::kHubFlagRequireLaser;
using toporoom::adapters::kHubOpSingle;
using toporoom::adapters::kHubSourceInvalid;
using toporoom::adapters::kHubSourceLaser;
using toporoom::adapters::kHubStatusOk;

namespace {

std::string hex_of(const uint8_t* p, std::size_t n) {
  static const char* kHex = "0123456789ABCDEF";
  std::string out;
  out.resize(n * 2);
  for (std::size_t i = 0; i < n; ++i) {
    out[2 * i] = kHex[(p[i] >> 4) & 0xF];
    out[2 * i + 1] = kHex[p[i] & 0xF];
  }
  return out;
}

}  // namespace

TEST(HubProtocol, MeasureCommandGoldenBytes) {
  const auto cmd = HubGattCodec::pack_measure_cmd(kHubOpSingle, kHubFlagRequireLaser, 1000);
  EXPECT_EQ(hex_of(cmd.data(), cmd.size()), "0101E803");
}

TEST(HubProtocol, LengthNotifyGoldenBytes900mm) {
  HubLengthNotify n;
  n.length_mm = 900;
  n.status = kHubStatusOk;
  n.source = kHubSourceLaser;
  n.sequence = 1;
  n.timestamp_ms = 0;
  const auto bytes = HubGattCodec::pack_length_notify(n);
  EXPECT_EQ(hex_of(bytes.data(), bytes.size()), "840300000001010000000000");
  const auto parsed = HubGattCodec::parse_length_notify(bytes.data(), bytes.size());
  ASSERT_TRUE(parsed);
  EXPECT_EQ(parsed->length_mm, 900);
  EXPECT_EQ(parsed->source, kHubSourceLaser);
}

TEST(HubProtocol, JrtUartGoldenFrames) {
  const auto cmd = JrtUartCodec::pack_single_measure();
  EXPECT_EQ(hex_of(cmd.data(), cmd.size()), "AA0000200001000021");
  const uint8_t result[9] = {0xAA, 0x00, 0x00, 0x22, 0x00, 0x00, 0x03, 0x84, 0xA9};
  const auto mm = JrtUartCodec::parse_result_mm(result, sizeof(result), 1);
  ASSERT_TRUE(mm);
  EXPECT_EQ(*mm, 900);
}

TEST(HubProtocol, BluetoothPortAcceptsBinaryNotify) {
  FakeBleLaserTransport ble;
  ble.add_device({"hub_1", "TopoRoom Hub", "toporoom_hub_c3", "laser"});
  HubLengthNotify n;
  n.length_mm = 4000;
  n.status = kHubStatusOk;
  n.source = kHubSourceLaser;
  n.sequence = 2;
  n.timestamp_ms = 42;
  const auto packed = HubGattCodec::pack_length_notify(n);
  ble.enqueue_payload(std::string(reinterpret_cast<const char*>(packed.data()), packed.size()));
  BluetoothLaserPort laser(ble);
  laser.connect("hub_1");
  const auto sample = laser.measure_once(1000);
  EXPECT_EQ(sample.source, "laser");
  EXPECT_EQ(sample.value_mm, 4000);
  EXPECT_EQ(sample.instrument_id, "hub_1");
}

TEST(HubProtocol, RfSourceRejectedOnNotify) {
  FakeBleLaserTransport ble;
  HubLengthNotify n;
  n.length_mm = 1200;
  n.status = kHubStatusOk;
  n.source = kHubSourceInvalid;
  const auto packed = HubGattCodec::pack_length_notify(n);
  ble.enqueue_payload(std::string(reinterpret_cast<const char*>(packed.data()), packed.size()));
  BluetoothLaserPort laser(ble);
  laser.connect("hub_1");
  EXPECT_THROW(laser.read_length_mm(), CaptureTransportError);
}

TEST(HubProtocol, AsciiLenStillWorksForFake) {
  const auto sample = HubGattCodec::parse_laser_payload("LEN 2800", "fake");
  EXPECT_EQ(sample.value_mm, 2800);
  EXPECT_EQ(sample.source, "laser");
}
