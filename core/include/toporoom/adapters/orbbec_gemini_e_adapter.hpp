#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/ports/depth_stream_port.hpp"

namespace toporoom::adapters {

class DepthReplayFixture;

/*
 * VendorSdk primary adapter for locked SKU orbbec_gemini_e.
 * Does not include Orbbec headers. Link the official Android AAR / NDK at the
 * host (see mobile/android/ORBBEC.md) and inject a backend; CI uses replay.
 */
class OrbbecGeminiEDepthAdapter : public ports::DepthStreamPort {
 public:
  static constexpr const char* kSku = "orbbec_gemini_e";
  static constexpr const char* kVid = "2BC5";
  static constexpr const char* kPid = "065C";
  static constexpr const char* kFirmware = "3460";
  static constexpr const char* kPrinciple = "structured_light";

  OrbbecGeminiEDepthAdapter();
  explicit OrbbecGeminiEDepthAdapter(DepthReplayFixture& backend);

  static ports::AccessoryProfile profile();

  std::vector<ports::AccessoryProfile> discover() override;
  ports::StreamHandle open(const std::string& device_id,
                           const ports::DepthStreamOptions& options) override;
  ports::DepthFrameDTO read_frame(int timeout_ms) override;
  ports::CameraIntrinsics get_intrinsics() override;
  std::optional<ports::Extrinsics> get_extrinsics_to_imu() override;
  std::string get_firmware_version() override;
  void close() override;

  bool sdk_linked() const noexcept { return backend_ != nullptr; }

 private:
  DepthReplayFixture* backend_ = nullptr;
  bool open_ = false;
};

/* UVC is transport only — not a pass for Stage-Gate, not a depth principle. */
class OrbbecGeminiEUvcStub : public ports::DepthStreamPort {
 public:
  OrbbecGeminiEUvcStub();
  explicit OrbbecGeminiEUvcStub(DepthReplayFixture& backend);

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
