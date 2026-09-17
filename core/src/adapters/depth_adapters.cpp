#include "toporoom/adapters/depth_adapters.hpp"

#include "toporoom/adapters/capture_transport_error.hpp"

namespace toporoom::adapters {
namespace {

ports::AccessoryProfile vendor_profile() {
  ports::AccessoryProfile profile;
  profile.device_id = "vendor_depth";
  profile.name = "Vendor SDK depth";
  profile.vid = "2BC5";
  profile.pid = "065C";
  profile.sku = "orbbec_gemini_e";
  profile.principle = "structured_light";
  profile.power_hint = "powered_hub_recommended";
  profile.firmware_version = "3460";
  return profile;
}

ports::AccessoryProfile uvc_profile() {
  ports::AccessoryProfile profile;
  profile.device_id = "uvc_depth";
  profile.name = "UVC transport";
  profile.vid = "2BC5";
  profile.pid = "065C";
  profile.sku = "orbbec_gemini_e";
  profile.principle = "uvc_transport";
  profile.power_hint = "UVC is transport, not a depth principle";
  profile.firmware_version = "3460";
  return profile;
}

void require_backend(DepthReplayFixture* backend) {
  if (backend == nullptr) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "depth hardware not present (CI stub)");
  }
}

}  // namespace

void DepthReplayFixture::enqueue(ports::DepthFrameDTO frame) {
  frames_.push_back(std::move(frame));
}

void DepthReplayFixture::reset_playback() { index_ = 0; }

std::vector<ports::AccessoryProfile> DepthReplayFixture::discover() {
  return {vendor_profile()};
}

ports::StreamHandle DepthReplayFixture::open(const std::string& device_id,
                                             const ports::DepthStreamOptions&) {
  open_ = true;
  index_ = 0;
  device_id_ = device_id;
  return ports::StreamHandle{device_id};
}

ports::DepthFrameDTO DepthReplayFixture::read_frame(int) {
  if (!open_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "depth stream not started");
  }
  if (index_ >= frames_.size()) {
    open_ = false;
    throw CaptureTransportError(CaptureTransportError::Kind::Disconnected,
                                "depth disconnected");
  }
  return frames_[index_++];
}

ports::CameraIntrinsics DepthReplayFixture::get_intrinsics() {
  return {500, 500, 320, 240};
}

std::optional<ports::Extrinsics> DepthReplayFixture::get_extrinsics_to_imu() {
  return ports::Extrinsics{{1, 0, 0, 0, 1, 0, 0, 0, 1}, {0, 0, 0}};
}

std::string DepthReplayFixture::get_firmware_version() { return "3460"; }

void DepthReplayFixture::close() { open_ = false; }

VendorSdkDepthAdapter::VendorSdkDepthAdapter() = default;

VendorSdkDepthAdapter::VendorSdkDepthAdapter(DepthReplayFixture& backend)
    : backend_(&backend) {}

std::vector<ports::AccessoryProfile> VendorSdkDepthAdapter::discover() {
  return {vendor_profile()};
}

ports::StreamHandle VendorSdkDepthAdapter::open(const std::string& device_id,
                                                const ports::DepthStreamOptions& options) {
  require_backend(backend_);
  open_ = true;
  return backend_->open(device_id, options);
}

ports::DepthFrameDTO VendorSdkDepthAdapter::read_frame(int timeout_ms) {
  require_backend(backend_);
  if (!open_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "depth stream not started");
  }
  return backend_->read_frame(timeout_ms);
}

ports::CameraIntrinsics VendorSdkDepthAdapter::get_intrinsics() {
  require_backend(backend_);
  return backend_->get_intrinsics();
}

std::optional<ports::Extrinsics> VendorSdkDepthAdapter::get_extrinsics_to_imu() {
  require_backend(backend_);
  return backend_->get_extrinsics_to_imu();
}

std::string VendorSdkDepthAdapter::get_firmware_version() {
  require_backend(backend_);
  return backend_->get_firmware_version();
}

void VendorSdkDepthAdapter::close() {
  open_ = false;
  if (backend_ != nullptr) backend_->close();
}

UvcDepthAdapter::UvcDepthAdapter() = default;

UvcDepthAdapter::UvcDepthAdapter(DepthReplayFixture& backend) : backend_(&backend) {}

std::vector<ports::AccessoryProfile> UvcDepthAdapter::discover() { return {uvc_profile()}; }

ports::StreamHandle UvcDepthAdapter::open(const std::string& device_id,
                                          const ports::DepthStreamOptions& options) {
  require_backend(backend_);
  open_ = true;
  return backend_->open(device_id, options);
}

ports::DepthFrameDTO UvcDepthAdapter::read_frame(int timeout_ms) {
  require_backend(backend_);
  if (!open_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "depth stream not started");
  }
  return backend_->read_frame(timeout_ms);
}

ports::CameraIntrinsics UvcDepthAdapter::get_intrinsics() {
  require_backend(backend_);
  return backend_->get_intrinsics();
}

std::optional<ports::Extrinsics> UvcDepthAdapter::get_extrinsics_to_imu() {
  require_backend(backend_);
  return backend_->get_extrinsics_to_imu();
}

std::string UvcDepthAdapter::get_firmware_version() {
  require_backend(backend_);
  return backend_->get_firmware_version();
}

void UvcDepthAdapter::close() {
  open_ = false;
  if (backend_ != nullptr) backend_->close();
}

}  // namespace toporoom::adapters
