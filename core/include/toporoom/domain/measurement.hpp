#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"

namespace toporoom::domain {

struct MeasurementTarget {
  std::string entity_type;
  std::string entity_id;
  std::string field;
};

struct Measurement {
  std::string id;
  MeasurementKind kind = MeasurementKind::Length;
  double value_mm = 0;
  MeasurementSource source = MeasurementSource::Typed;
  std::optional<std::string> instrument_id;
  std::vector<std::string> between;
  std::optional<MeasurementTarget> target;
};

}  // namespace toporoom::domain
