#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace toporoom::ports {

struct AccessoryProfile {
  std::string device_id;
  std::string name;
  std::string vid;
  std::string pid;
  std::string sku;
  std::string principle;
  std::string power_hint;
  std::string firmware_version;
};

struct StreamHandle {
  std::string device_id;
};

struct DepthStreamOptions {
  int fps = 30;
};

struct DepthFrameDTO {
  int width = 0;
  int height = 0;
  long long timestamp = 0;
  std::vector<float> depths_mm;
};

struct ColorFrameDTO {
  int width = 0;
  int height = 0;
  long long timestamp = 0;
  std::vector<std::uint8_t> rgba;
};

struct CameraIntrinsics {
  double fx = 0;
  double fy = 0;
  double cx = 0;
  double cy = 0;
};

struct Extrinsics {
  std::vector<double> rotation;
  std::vector<double> translation_mm;
};

class DepthStreamPort {
 public:
  virtual ~DepthStreamPort() = default;
  virtual std::vector<AccessoryProfile> discover() = 0;
  virtual StreamHandle open(const std::string& device_id,
                            const DepthStreamOptions& options) = 0;
  virtual DepthFrameDTO read_frame(int timeout_ms) = 0;
  virtual CameraIntrinsics get_intrinsics() = 0;
  virtual std::optional<Extrinsics> get_extrinsics_to_imu() = 0;
  virtual std::string get_firmware_version() = 0;
  virtual void close() = 0;
};

}  // namespace toporoom::ports
