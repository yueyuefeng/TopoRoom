#pragma once

#include <optional>

#include "toporoom/ports/depth_stream_port.hpp"
#include "toporoom/ports/notify_port.hpp"

namespace toporoom::app {

class DepthCaptureService {
 public:
  DepthCaptureService(ports::DepthStreamPort& depth, ports::NotifyPort& notify)
      : depth_(depth), notify_(notify) {}

  std::optional<ports::StreamHandle> start(const std::string& device_id,
                                           const ports::DepthStreamOptions& options);
  std::optional<ports::DepthFrameDTO> next_frame(int timeout_ms);
  void stop();

 private:
  ports::DepthStreamPort& depth_;
  ports::NotifyPort& notify_;
};

}  // namespace toporoom::app
