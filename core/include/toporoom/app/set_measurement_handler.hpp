#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/app/document_io.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/measurement.hpp"

namespace toporoom::app {

struct SetMeasurementCommand {
  std::string document_id;
  std::string measurement_id;
  domain::MeasurementKind kind = domain::MeasurementKind::Length;
  double value_mm = 0;
  domain::MeasurementSource source = domain::MeasurementSource::Typed;
  std::optional<std::string> instrument_id;
  std::vector<std::string> between;
  std::optional<domain::MeasurementTarget> target;
};

class SetMeasurementHandler {
 public:
  SetMeasurementHandler(ports::DocumentStorePort& store, GeometryRebuildPolicy& rebuild)
      : store_(store), rebuild_(rebuild) {}

  CommandResult execute(const SetMeasurementCommand& command);

 private:
  ports::DocumentStorePort& store_;
  GeometryRebuildPolicy& rebuild_;
};

}  // namespace toporoom::app
