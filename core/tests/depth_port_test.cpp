#include <type_traits>

#include <gtest/gtest.h>

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/depth_adapters.hpp"
#include "toporoom/adapters/recording_notify_port.hpp"
#include "toporoom/app/depth_capture_service.hpp"
#include "toporoom/ports/depth_stream_port.hpp"

using toporoom::adapters::CaptureTransportError;
using toporoom::adapters::DepthReplayFixture;
using toporoom::adapters::RecordingNotifyPort;
using toporoom::adapters::UvcDepthAdapter;
using toporoom::adapters::VendorSdkDepthAdapter;
using toporoom::app::DepthCaptureService;
using toporoom::ports::DepthFrameDTO;
using toporoom::ports::DepthStreamOptions;
using toporoom::ports::FaultCode;

namespace {

DepthFrameDTO sample_frame(long long timestamp, float depth_mm) {
  DepthFrameDTO frame;
  frame.width = 2;
  frame.height = 1;
  frame.timestamp = timestamp;
  frame.depths_mm = {depth_mm, depth_mm + 1};
  frame.pose.valid = true;
  frame.pose.tx_mm = 10;
  frame.pose.tz_mm = 20;
  return frame;
}

}  // namespace

TEST(DepthPort, VendorAndUvcShareContract) {
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::DepthStreamPort>);
  DepthReplayFixture replay;
  replay.enqueue(sample_frame(1, 1200));
  VendorSdkDepthAdapter vendor(replay);
  UvcDepthAdapter uvc(replay);
  EXPECT_EQ(vendor.discover()[0].principle, "structured_light");
  EXPECT_EQ(uvc.discover()[0].principle, "uvc_transport");
  vendor.open("vendor_depth", {});
  const auto frame = vendor.read_frame(10);
  EXPECT_EQ(frame.width, 2);
  EXPECT_TRUE(frame.pose.valid);
  EXPECT_EQ(frame.depths_mm.size(), 2u);
  vendor.close();
}

TEST(DepthPort, ReplayFixtureIsDeterministic) {
  DepthReplayFixture replay;
  replay.enqueue(sample_frame(1, 1000));
  replay.enqueue(sample_frame(2, 1100));
  replay.open("replay", {});
  EXPECT_EQ(replay.read_frame(0).timestamp, 1);
  EXPECT_EQ(replay.read_frame(0).timestamp, 2);
  replay.close();
  replay.reset_playback();
  replay.open("replay", {});
  EXPECT_EQ(replay.read_frame(0).depths_mm[0], 1000);
  EXPECT_EQ(replay.read_frame(0).timestamp, 2);
}

TEST(DepthPort, StartStopAndCiStubHasNoHardware) {
  DepthReplayFixture replay;
  replay.enqueue(sample_frame(1, 800));
  VendorSdkDepthAdapter vendor(replay);
  const auto handle = vendor.open("vendor_depth", DepthStreamOptions{15});
  EXPECT_EQ(handle.device_id, "vendor_depth");
  EXPECT_TRUE(replay.streaming());
  vendor.close();
  EXPECT_FALSE(replay.streaming());

  VendorSdkDepthAdapter absent;
  EXPECT_THROW(absent.open("vendor_depth", {}), CaptureTransportError);
}

TEST(DepthCapture, DisconnectNotifiesFault) {
  DepthReplayFixture replay;
  RecordingNotifyPort notify;
  VendorSdkDepthAdapter vendor(replay);
  DepthCaptureService service(vendor, notify);
  ASSERT_TRUE(service.start("vendor_depth", {}));
  EXPECT_EQ(service.next_frame(0), std::nullopt);
  ASSERT_FALSE(notify.errors.empty());
  ASSERT_FALSE(notify.faults.empty());
  EXPECT_EQ(notify.faults[0].code, FaultCode::InvalidGeometry);
  service.stop();
}

TEST(DepthPort, UvcIsTransportNotPrinciple) {
  UvcDepthAdapter uvc;
  const auto profile = uvc.discover()[0];
  EXPECT_EQ(profile.principle, "uvc_transport");
  EXPECT_NE(profile.power_hint.find("transport"), std::string::npos);
}
