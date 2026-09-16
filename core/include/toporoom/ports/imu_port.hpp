#pragma once

#include <stdexcept>
#include <string>
#include <utility>

namespace toporoom::ports {

struct ImuSampleDTO {
  double acc_x = 0;
  double acc_y = 0;
  double acc_z = 0;
  double gyro_x = 0;
  double gyro_y = 0;
  double gyro_z = 0;
  long long timestamp = 0;
};

class ImuPort {
 public:
  virtual ~ImuPort() = default;
  virtual ImuSampleDTO read_sample() = 0;
  virtual bool degraded() const = 0;
  virtual std::string degrade_reason() const = 0;
};

}  // namespace toporoom::ports
