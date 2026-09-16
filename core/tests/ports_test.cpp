#include <type_traits>

#include <gtest/gtest.h>

#include "toporoom/ports/depth_stream_port.hpp"
#include "toporoom/ports/document_store_port.hpp"
#include "toporoom/ports/geometry_port.hpp"
#include "toporoom/ports/laser_rangefinder_port.hpp"
#include "toporoom/ports/notify_port.hpp"
#include "toporoom/ports/imu_port.hpp"

TEST(Ports, AbstractInterfaces) {
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::GeometryPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::LaserRangefinderPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::DepthStreamPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::DocumentStorePort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::NotifyPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::ImuPort>);
}
