#pragma once

#include "toporoom/ports/imu_port.hpp"

namespace toporoom::adapters {

class ModuleImuAdapter : public ports::ImuPort {
 public:
  explicit ModuleImuAdapter(ports::ImuSampleDTO sample);
  ports::ImuSampleDTO read_sample() override;
  bool degraded() const override { return false; }
  std::string degrade_reason() const override { return {}; }

 private:
  ports::ImuSampleDTO sample_;
};

class PhoneImuAdapter : public ports::ImuPort {
 public:
  explicit PhoneImuAdapter(ports::ImuSampleDTO sample);
  ports::ImuSampleDTO read_sample() override;
  bool degraded() const override { return true; }
  std::string degrade_reason() const override {
    return "module IMU missing; phone IMU fallback";
  }

 private:
  ports::ImuSampleDTO sample_;
};

class MissingImuAdapter : public ports::ImuPort {
 public:
  ports::ImuSampleDTO read_sample() override;
  bool degraded() const override { return true; }
  std::string degrade_reason() const override {
    return "no IMU; annotate-only, skip gravity align";
  }
};

}  // namespace toporoom::adapters
