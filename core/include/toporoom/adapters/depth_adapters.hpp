#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/ports/depth_stream_port.hpp"

namespace toporoom::adapters {

class DepthReplayFixture : public ports::DepthStreamPort {
 public:
  void enqueue(ports::DepthFrameDTO frame);
  void reset_playback();
  bool streaming() const noexcept { return open_; }

  std::vector<ports::AccessoryProfile> discover() override;
  ports::StreamHandle open(const std::string& device_id,
                           const ports::DepthStreamOptions& options) override;
  ports::DepthFrameDTO read_frame(int timeout_ms) override;
  ports::CameraIntrinsics get_intrinsics() override;
  std::optional<ports::Extrinsics> get_extrinsics_to_imu() override;
  std::string get_firmware_version() override;
  void close() override;

 private:
  std::vector<ports::DepthFrameDTO> frames_;
  std::size_t index_ = 0;
  bool open_ = false;
  std::string device_id_;
};

class VendorSdkDepthAdapter : public ports::DepthStreamPort {
 public:
  VendorSdkDepthAdapter();
  explicit VendorSdkDepthAdapter(DepthReplayFixture& backend);

  std::vector<ports::AccessoryProfile> discover() override;
  ports::StreamHandle open(const std::string& device_id,
                           const ports::DepthStreamOptions& options) override;
  ports::DepthFrameDTO read_frame(int timeout_ms) override;
  ports::CameraIntrinsics get_intrinsics() override;
  std::optional<ports::Extrinsics> get_extrinsics_to_imu() override;
  std::string get_firmware_version() override;
  void close() override;

 private:
  DepthReplayFixture* backend_ = nullptr;
  bool open_ = false;
};

class UvcDepthAdapter : public ports::DepthStreamPort {
 public:
  UvcDepthAdapter();
  explicit UvcDepthAdapter(DepthReplayFixture& backend);

  std::vector<ports::AccessoryProfile> discover() override;
  ports::StreamHandle open(const std::string& device_id,
                           const ports::DepthStreamOptions& options) override;
  ports::DepthFrameDTO read_frame(int timeout_ms) override;
  ports::CameraIntrinsics get_intrinsics() override;
  std::optional<ports::Extrinsics> get_extrinsics_to_imu() override;
  std::string get_firmware_version() override;
  void close() override;

 private:
  DepthReplayFixture* backend_ = nullptr;
  bool open_ = false;
};

}  // namespace toporoom::adapters
