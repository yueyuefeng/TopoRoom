#include "toporoom/adapters/orbbec_gemini_e_adapter.hpp"

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/depth_adapters.hpp"

namespace toporoom::adapters {
namespace {

void require_backend(DepthReplayFixture* backend, const char* msg) {
  if (backend == nullptr) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected, msg);
  }
}

}  // namespace

ports::AccessoryProfile OrbbecGeminiEDepthAdapter::profile() {
  ports::AccessoryProfile p;
  p.device_id = "orbbec_gemini_e";
  p.name = "Orbbec Gemini E";
  p.vid = kVid;
  p.pid = kPid;
  p.sku = kSku;
  p.principle = kPrinciple;
  p.power_hint =
      "USB2 Type-C device on phone OTG; powered_hub_a recommended; no onboard IMU";
  p.firmware_version = kFirmware;
  return p;
}

OrbbecGeminiEDepthAdapter::OrbbecGeminiEDepthAdapter() = default;

OrbbecGeminiEDepthAdapter::OrbbecGeminiEDepthAdapter(DepthReplayFixture& backend)
    : backend_(&backend) {}

std::vector<ports::AccessoryProfile> OrbbecGeminiEDepthAdapter::discover() {
  return {profile()};
}

ports::StreamHandle OrbbecGeminiEDepthAdapter::open(
    const std::string& device_id, const ports::DepthStreamOptions& options) {
  require_backend(backend_,
                  "Orbbec SDK not linked (TOPOROOM_ORBBEC_SDK / official AAR); see "
                  "mobile/android/ORBBEC.md");
  open_ = true;
  return backend_->open(device_id, options);
}

ports::DepthFrameDTO OrbbecGeminiEDepthAdapter::read_frame(int timeout_ms) {
  require_backend(backend_, "Orbbec SDK not linked");
  if (!open_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "gemini e stream not started");
  }
  return backend_->read_frame(timeout_ms);
}

ports::CameraIntrinsics OrbbecGeminiEDepthAdapter::get_intrinsics() {
  require_backend(backend_, "Orbbec SDK not linked");
  return backend_->get_intrinsics();
}

std::optional<ports::Extrinsics> OrbbecGeminiEDepthAdapter::get_extrinsics_to_imu() {
  require_backend(backend_, "Orbbec SDK not linked");
  /* Gemini E has no module IMU; phone IMU is P0 fallback. */
  return std::nullopt;
}

std::string OrbbecGeminiEDepthAdapter::get_firmware_version() {
  return kFirmware;
}

void OrbbecGeminiEDepthAdapter::close() {
  open_ = false;
  if (backend_ != nullptr) backend_->close();
}

OrbbecGeminiEUvcStub::OrbbecGeminiEUvcStub() = default;

OrbbecGeminiEUvcStub::OrbbecGeminiEUvcStub(DepthReplayFixture& backend)
    : backend_(&backend) {}

std::vector<ports::AccessoryProfile> OrbbecGeminiEUvcStub::discover() {
  auto p = OrbbecGeminiEDepthAdapter::profile();
  p.device_id = "orbbec_gemini_e_uvc";
  p.name = "Orbbec Gemini E UVC transport stub";
  p.principle = "uvc_transport";
  p.power_hint = "UVC is transport, not a depth principle; Stage-Gate uses VendorSdk";
  return {p};
}

ports::StreamHandle OrbbecGeminiEUvcStub::open(const std::string& device_id,
                                               const ports::DepthStreamOptions& options) {
  require_backend(backend_, "gemini e UVC not exposed by firmware (stub)");
  open_ = true;
  return backend_->open(device_id, options);
}

ports::DepthFrameDTO OrbbecGeminiEUvcStub::read_frame(int timeout_ms) {
  require_backend(backend_, "gemini e UVC stub");
  if (!open_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "uvc stub stream not started");
  }
  return backend_->read_frame(timeout_ms);
}

ports::CameraIntrinsics OrbbecGeminiEUvcStub::get_intrinsics() {
  require_backend(backend_, "gemini e UVC stub");
  return backend_->get_intrinsics();
}

std::optional<ports::Extrinsics> OrbbecGeminiEUvcStub::get_extrinsics_to_imu() {
  return std::nullopt;
}

std::string OrbbecGeminiEUvcStub::get_firmware_version() {
  return OrbbecGeminiEDepthAdapter::kFirmware;
}

void OrbbecGeminiEUvcStub::close() {
  open_ = false;
  if (backend_ != nullptr) backend_->close();
}

}  // namespace toporoom::adapters
