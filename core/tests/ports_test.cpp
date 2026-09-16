#include <type_traits>

#include <gtest/gtest.h>

#include "toporoom/ports/cloud_sync_port.hpp"
#include "toporoom/ports/depth_stream_port.hpp"
#include "toporoom/ports/document_store_port.hpp"
#include "toporoom/ports/furnishing_port.hpp"
#include "toporoom/ports/geometry_port.hpp"
#include "toporoom/ports/imu_port.hpp"
#include "toporoom/ports/laser_rangefinder_port.hpp"
#include "toporoom/ports/mep_port.hpp"
#include "toporoom/ports/notify_port.hpp"
#include "toporoom/ports/takeoff_quote_port.hpp"

TEST(Ports, AbstractInterfaces) {
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::GeometryPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::LaserRangefinderPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::DepthStreamPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::DocumentStorePort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::NotifyPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::ImuPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::MepPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::FurnishingLibraryPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::CloudSyncPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::TakeoffQuotePort>);
}
