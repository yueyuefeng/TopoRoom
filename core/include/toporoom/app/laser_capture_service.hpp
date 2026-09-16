#pragma once

#include <optional>
#include <string>

#include "toporoom/app/document_io.hpp"
#include "toporoom/app/set_measurement_handler.hpp"
#include "toporoom/ports/laser_rangefinder_port.hpp"
#include "toporoom/ports/notify_port.hpp"

namespace toporoom::app {

struct LaserCaptureCommand {
  std::string document_id;
  std::string measurement_id;
  std::string device_id;
  std::optional<domain::MeasurementTarget> target;
};

class LaserCaptureService {
 public:
  LaserCaptureService(ports::LaserRangefinderPort& laser, ports::DocumentStorePort& store,
                      GeometryRebuildPolicy& rebuild, ports::NotifyPort& notify)
      : laser_(laser), handler_(store, rebuild), store_(store), notify_(notify) {}

  std::optional<CommandResult> capture(const LaserCaptureCommand& command);

 private:
  ports::LaserRangefinderPort& laser_;
  SetMeasurementHandler handler_;
  ports::DocumentStorePort& store_;
  ports::NotifyPort& notify_;
};

}  // namespace toporoom::app
