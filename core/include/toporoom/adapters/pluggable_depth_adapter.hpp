#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/ports/depth_stream_port.hpp"

namespace toporoom::adapters {

class DepthReplayFixture;

enum class DepthSkuKind { Fake, DabaiDcw, DualRgbUvc };

struct DepthSkuSpec {
  DepthSkuKind kind = DepthSkuKind::Fake;
  const char* sku = "fake";
  const char* vid = "";
  const char* pid = "";
  const char* firmware = "replay";
  const char* principle = "replay";
  const char* name = "Fake / replay depth";
  const char* power_hint = "CI replay; no USB";
};

DepthSkuSpec depth_sku_spec(DepthSkuKind kind);
std::optional<DepthSkuKind> parse_depth_sku(const std::string& sku);

/*
 * Pluggable DepthStreamPort: dabai_dcw | dual_rgb_uvc | fake.
 * No vendor USB/Orbbec includes. Track A (DaBai) still needs an official
 * OpenNI/SDK backend injected later; Track B must not claim ASIC depth.
 */
class PluggableDepthAdapter : public ports::DepthStreamPort {
 public:
  explicit PluggableDepthAdapter(DepthSkuKind kind = DepthSkuKind::Fake);
  PluggableDepthAdapter(DepthSkuKind kind, DepthReplayFixture& backend);

  DepthSkuKind kind() const noexcept { return spec_.kind; }
  const DepthSkuSpec& spec() const noexcept { return spec_; }
  bool sdk_linked() const noexcept { return backend_ != nullptr; }
  bool asic_depth() const noexcept { return spec_.kind == DepthSkuKind::DabaiDcw; }
  bool depth_fit_low_confidence() const noexcept {
    return spec_.kind == DepthSkuKind::DualRgbUvc;
  }

  std::vector<ports::AccessoryProfile> discover() override;
  ports::StreamHandle open(const std::string& device_id,
                           const ports::DepthStreamOptions& options) override;
  ports::DepthFrameDTO read_frame(int timeout_ms) override;
  ports::CameraIntrinsics get_intrinsics() override;
  std::optional<ports::Extrinsics> get_extrinsics_to_imu() override;
  std::string get_firmware_version() override;
  void close() override;

  ports::AccessoryProfile profile() const;

 private:
  DepthSkuSpec spec_{};
  DepthReplayFixture* backend_ = nullptr;
  bool open_ = false;
};

}  // namespace toporoom::adapters
