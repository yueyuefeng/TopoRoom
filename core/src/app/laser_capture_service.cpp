#include "toporoom/app/laser_capture_service.hpp"

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/domain/kinds.hpp"

namespace toporoom::app {

std::optional<CommandResult> LaserCaptureService::capture(
    const LaserCaptureCommand& command) {
  const auto before = store_.load(command.document_id);
  try {
    laser_.connect(command.device_id);
    const auto sample = laser_.read_length_mm();
    SetMeasurementCommand measurement;
    measurement.document_id = command.document_id;
    measurement.measurement_id = command.measurement_id;
    measurement.value_mm = sample.value_mm;
    measurement.instrument_id = sample.instrument_id;
    measurement.target = command.target;
    if (sample.source == "laser") {
      measurement.source = domain::MeasurementSource::Laser;
    } else if (sample.source == "typed") {
      measurement.source = domain::MeasurementSource::Typed;
    } else {
      notify_.error("rf_ble is never a dimension source");
      return std::nullopt;
    }
    return handler_.execute(measurement);
  } catch (const adapters::CaptureTransportError& error) {
    notify_.error(error.what());
    const auto after = store_.load(command.document_id);
    if (before && after) {
      if (before->revision != after->revision) {
        notify_.error("laser capture corrupted document");
      }
    }
    return std::nullopt;
  }
}

}  // namespace toporoom::app
