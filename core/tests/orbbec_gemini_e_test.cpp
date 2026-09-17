#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/depth_adapters.hpp"
#include "toporoom/adapters/orbbec_gemini_e_adapter.hpp"

using toporoom::adapters::CaptureTransportError;
using toporoom::adapters::DepthReplayFixture;
using toporoom::adapters::OrbbecGeminiEDepthAdapter;
using toporoom::adapters::OrbbecGeminiEUvcStub;
using toporoom::ports::DepthFrameDTO;

namespace {

DepthFrameDTO sample_frame() {
  DepthFrameDTO frame;
  frame.width = 2;
  frame.height = 1;
  frame.timestamp = 7;
  frame.depths_mm = {1200.f, 1210.f};
  return frame;
}

}  // namespace

TEST(GeminiE, ProfileIsLockedSku) {
  const auto p = OrbbecGeminiEDepthAdapter::profile();
  EXPECT_EQ(p.sku, "orbbec_gemini_e");
  EXPECT_EQ(p.vid, "2BC5");
  EXPECT_EQ(p.pid, "065C");
  EXPECT_EQ(p.firmware_version, "3460");
  EXPECT_EQ(p.principle, "structured_light");
  EXPECT_NE(p.power_hint.find("no onboard IMU"), std::string::npos);
}

TEST(GeminiE, AbsentSdkThrowsWithoutClaimingHardware) {
  OrbbecGeminiEDepthAdapter adapter;
  EXPECT_FALSE(adapter.sdk_linked());
  EXPECT_THROW(adapter.open("orbbec_gemini_e", {}), CaptureTransportError);
}

TEST(GeminiE, ReplayBackendStreamsAndHasNoModuleImu) {
  DepthReplayFixture replay;
  replay.enqueue(sample_frame());
  OrbbecGeminiEDepthAdapter adapter(replay);
  EXPECT_TRUE(adapter.sdk_linked());
  adapter.open("orbbec_gemini_e", {});
  const auto frame = adapter.read_frame(10);
  EXPECT_EQ(frame.timestamp, 7);
  EXPECT_EQ(adapter.get_firmware_version(), "3460");
  EXPECT_FALSE(adapter.get_extrinsics_to_imu().has_value());
  adapter.close();
}

TEST(GeminiE, UvcStubIsTransportNotPrinciple) {
  OrbbecGeminiEUvcStub uvc;
  const auto p = uvc.discover()[0];
  EXPECT_EQ(p.principle, "uvc_transport");
  EXPECT_EQ(p.sku, "orbbec_gemini_e");
  EXPECT_THROW(uvc.open("orbbec_gemini_e_uvc", {}), CaptureTransportError);
}
