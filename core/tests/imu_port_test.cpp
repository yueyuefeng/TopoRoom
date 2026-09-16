#include <type_traits>

#include <gtest/gtest.h>

#include "toporoom/adapters/imu_adapters.hpp"
#include "toporoom/ports/imu_port.hpp"

using toporoom::adapters::MissingImuAdapter;
using toporoom::adapters::ModuleImuAdapter;
using toporoom::adapters::PhoneImuAdapter;
using toporoom::ports::ImuSampleDTO;

TEST(ImuPort, ModuleNotDegraded) {
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::ImuPort>);
  ImuSampleDTO sample;
  sample.acc_z = 9.8;
  sample.timestamp = 42;
  ModuleImuAdapter imu(sample);
  EXPECT_FALSE(imu.degraded());
  EXPECT_TRUE(imu.degrade_reason().empty());
  EXPECT_EQ(imu.read_sample().timestamp, 42);
}

TEST(ImuPort, PhoneFallbackMarksDegrade) {
  PhoneImuAdapter imu({});
  EXPECT_TRUE(imu.degraded());
  EXPECT_NE(imu.degrade_reason().find("phone IMU"), std::string::npos);
}

TEST(ImuPort, MissingIsAnnotateOnly) {
  MissingImuAdapter imu;
  EXPECT_TRUE(imu.degraded());
  EXPECT_NE(imu.degrade_reason().find("annotate-only"), std::string::npos);
  EXPECT_EQ(imu.read_sample().timestamp, 0);
}
