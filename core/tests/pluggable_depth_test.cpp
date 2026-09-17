#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/depth_adapters.hpp"
#include "toporoom/adapters/pluggable_depth_adapter.hpp"

using toporoom::adapters::CaptureTransportError;
using toporoom::adapters::DepthReplayFixture;
using toporoom::adapters::DepthSkuKind;
using toporoom::adapters::parse_depth_sku;
using toporoom::adapters::PluggableDepthAdapter;
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

TEST(PluggableDepth, ParsesKnownSkusAndRejectsGeminiLock) {
  ASSERT_TRUE(parse_depth_sku("dabai_dcw"));
  ASSERT_TRUE(parse_depth_sku("dual_rgb_uvc"));
  ASSERT_TRUE(parse_depth_sku("fake"));
  EXPECT_FALSE(parse_depth_sku("orbbec_gemini_e"));
}

TEST(PluggableDepth, DabaiDcwIsAsicNotYen200) {
  PluggableDepthAdapter a(DepthSkuKind::DabaiDcw);
  const auto p = a.profile();
  EXPECT_EQ(p.sku, "dabai_dcw");
  EXPECT_EQ(p.vid, "2BC5");
  EXPECT_TRUE(p.pid.empty());
  EXPECT_EQ(p.firmware_version, "2460");
  EXPECT_EQ(p.principle, "structured_light");
  EXPECT_TRUE(a.asic_depth());
  EXPECT_FALSE(a.depth_fit_low_confidence());
  EXPECT_NE(p.power_hint.find("¥788"), std::string::npos);
  EXPECT_FALSE(a.sdk_linked());
  EXPECT_THROW(a.open("dabai_dcw", {}), CaptureTransportError);
}

TEST(PluggableDepth, DualRgbUvcIsAssistNotAsic) {
  PluggableDepthAdapter a(DepthSkuKind::DualRgbUvc);
  const auto p = a.profile();
  EXPECT_EQ(p.sku, "dual_rgb_uvc");
  EXPECT_EQ(p.principle, "uvc_transport");
  EXPECT_EQ(p.firmware_version, "uvc_host");
  EXPECT_FALSE(a.asic_depth());
  EXPECT_TRUE(a.depth_fit_low_confidence());
  EXPECT_THROW(a.open("dual_rgb_uvc", {}), CaptureTransportError);
}

TEST(PluggableDepth, FakeReplayStreamsWithoutModuleImu) {
  DepthReplayFixture replay;
  replay.enqueue(sample_frame());
  PluggableDepthAdapter a(DepthSkuKind::Fake, replay);
  EXPECT_EQ(a.profile().sku, "fake");
  a.open("fake", {});
  EXPECT_EQ(a.read_frame(10).timestamp, 7);
  EXPECT_EQ(a.get_firmware_version(), "replay");
  EXPECT_FALSE(a.get_extrinsics_to_imu().has_value());
  a.close();
}
