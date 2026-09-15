#pragma once

#include <optional>
#include <string>
#include <vector>

namespace toporoom::ports {

struct LaserDeviceProfile {
  std::string device_id;
  std::string name;
  std::string sku;
  std::string principle = "laser";
};

struct LaserHandle {
  std::string device_id;
};

struct MeasureSample {
  double value_mm = 0;
  long long timestamp = 0;
  std::string source;  // "laser" or "typed"
  std::string instrument_id;
  std::optional<int> raw_rssi;
};

class LaserRangefinderPort {
 public:
  virtual ~LaserRangefinderPort() = default;
  virtual std::vector<LaserDeviceProfile> discover() = 0;
  virtual LaserHandle connect(const std::string& device_id) = 0;
  virtual MeasureSample read_length_mm() = 0;
  virtual void disconnect() = 0;
};

}  // namespace toporoom::ports
