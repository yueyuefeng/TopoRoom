#include "toporoom/adapters/pluggable_depth_adapter.hpp"

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/depth_adapters.hpp"

namespace toporoom::adapters {
namespace {

const char* not_linked_message(DepthSkuKind kind) {
  switch (kind) {
    case DepthSkuKind::DabaiDcw:
      return "DaBai DCW OpenNI/SDK not linked (see mobile/android/DEPTH.md); "
             "not a ¥200 ASIC Type-C accessory";
    case DepthSkuKind::DualRgbUvc:
      return "dual_rgb_uvc has no on-module depth ASIC; UVC is assist only "
             "(depth_fit low-confidence). Inject a replay backend for CI";
    case DepthSkuKind::Fake:
    default:
      return "fake depth has no hardware; inject DepthReplayFixture";
  }
}

}  // namespace

DepthSkuSpec depth_sku_spec(DepthSkuKind kind) {
  DepthSkuSpec s;
  s.kind = kind;
  switch (kind) {
    case DepthSkuKind::DabaiDcw:
      s.sku = "dabai_dcw";
      s.vid = "2BC5";
      s.pid = "";  // confirm on unit; do not assume Gemini E 065C
      s.firmware = "2460";
      s.principle = "structured_light";
      s.name = "Orbbec DaBai DCW";
      s.power_hint =
          "USB2 ASIC depth ~¥788; powered_hub_a recommended; no IMU; not ¥200";
      break;
    case DepthSkuKind::DualRgbUvc:
      s.sku = "dual_rgb_uvc";
      s.vid = "";
      s.pid = "";
      s.firmware = "uvc_host";
      s.principle = "uvc_transport";
      s.name = "Dual RGB UVC assist";
      s.power_hint =
          "UVC is transport/assist, not a depth principle; depth_fit low-confidence";
      break;
    case DepthSkuKind::Fake:
    default:
      s.sku = "fake";
      s.firmware = "replay";
      s.principle = "replay";
      s.name = "Fake / replay depth";
      s.power_hint = "CI replay; no USB";
      break;
  }
  return s;
}

std::optional<DepthSkuKind> parse_depth_sku(const std::string& sku) {
  if (sku == "dabai_dcw") return DepthSkuKind::DabaiDcw;
  if (sku == "dual_rgb_uvc") return DepthSkuKind::DualRgbUvc;
  if (sku == "fake" || sku == "replay") return DepthSkuKind::Fake;
  return std::nullopt;
}

PluggableDepthAdapter::PluggableDepthAdapter(DepthSkuKind kind)
    : spec_(depth_sku_spec(kind)) {}

PluggableDepthAdapter::PluggableDepthAdapter(DepthSkuKind kind, DepthReplayFixture& backend)
    : spec_(depth_sku_spec(kind)), backend_(&backend) {}

ports::AccessoryProfile PluggableDepthAdapter::profile() const {
  ports::AccessoryProfile p;
  p.device_id = spec_.sku;
  p.name = spec_.name;
  p.vid = spec_.vid;
  p.pid = spec_.pid;
  p.sku = spec_.sku;
  p.principle = spec_.principle;
  p.power_hint = spec_.power_hint;
  p.firmware_version = spec_.firmware;
  return p;
}

std::vector<ports::AccessoryProfile> PluggableDepthAdapter::discover() { return {profile()}; }

ports::StreamHandle PluggableDepthAdapter::open(const std::string& device_id,
                                                const ports::DepthStreamOptions& options) {
  if (backend_ == nullptr) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                not_linked_message(spec_.kind));
  }
  open_ = true;
  return backend_->open(device_id, options);
}

ports::DepthFrameDTO PluggableDepthAdapter::read_frame(int timeout_ms) {
  if (backend_ == nullptr) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                not_linked_message(spec_.kind));
  }
  if (!open_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "pluggable depth stream not started");
  }
  return backend_->read_frame(timeout_ms);
}

ports::CameraIntrinsics PluggableDepthAdapter::get_intrinsics() {
  if (backend_ == nullptr) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                not_linked_message(spec_.kind));
  }
  return backend_->get_intrinsics();
}

std::optional<ports::Extrinsics> PluggableDepthAdapter::get_extrinsics_to_imu() {
  return std::nullopt;  // no module IMU on DaBai DCW or UVC dongles
}

std::string PluggableDepthAdapter::get_firmware_version() { return spec_.firmware; }

void PluggableDepthAdapter::close() {
  open_ = false;
  if (backend_ != nullptr) backend_->close();
}

}  // namespace toporoom::adapters
