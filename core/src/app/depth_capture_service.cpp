#include "toporoom/app/depth_capture_service.hpp"

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

std::optional<ports::StreamHandle> DepthCaptureService::start(
    const std::string& device_id, const ports::DepthStreamOptions& options) {
  try {
    return depth_.open(device_id, options);
  } catch (const adapters::CaptureTransportError& error) {
    notify_.error(error.what());
    notify_.geometry_fault({ports::FaultCode::Timeout, error.what(), {device_id}});
    return std::nullopt;
  }
}

std::optional<ports::DepthFrameDTO> DepthCaptureService::next_frame(int timeout_ms) {
  try {
    return depth_.read_frame(timeout_ms);
  } catch (const adapters::CaptureTransportError& error) {
    notify_.error(error.what());
    const auto code = error.kind() == adapters::CaptureTransportError::Kind::Timeout
                          ? ports::FaultCode::Timeout
                          : ports::FaultCode::InvalidGeometry;
    notify_.geometry_fault({code, error.what(), {}});
    return std::nullopt;
  }
}

void DepthCaptureService::stop() { depth_.close(); }

}  // namespace toporoom::app
