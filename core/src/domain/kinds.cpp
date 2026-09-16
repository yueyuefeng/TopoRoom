#include "toporoom/domain/kinds.hpp"

namespace toporoom::domain {

const char* to_string(WallKind kind) {
  switch (kind) {
    case WallKind::Exterior:
      return "exterior";
    case WallKind::Interior:
      return "interior";
    case WallKind::Partition:
      return "partition";
  }
  return "unknown";
}

const char* to_string(OpeningKind kind) {
  switch (kind) {
    case OpeningKind::Door:
      return "door";
    case OpeningKind::Window:
      return "window";
  }
  return "unknown";
}

const char* to_string(MeasurementSource source) {
  switch (source) {
    case MeasurementSource::Laser:
      return "laser";
    case MeasurementSource::Typed:
      return "typed";
    case MeasurementSource::DepthFit:
      return "depth_fit";
  }
  return "unknown";
}

std::optional<WallKind> wall_kind_from_string(std::string_view value) {
  if (value == "exterior") return WallKind::Exterior;
  if (value == "interior") return WallKind::Interior;
  if (value == "partition") return WallKind::Partition;
  return std::nullopt;
}

std::optional<OpeningKind> opening_kind_from_string(std::string_view value) {
  if (value == "door") return OpeningKind::Door;
  if (value == "window") return OpeningKind::Window;
  return std::nullopt;
}

std::optional<MeasurementSource> measurement_source_from_string(
    std::string_view value) {
  if (value == "laser") return MeasurementSource::Laser;
  if (value == "typed") return MeasurementSource::Typed;
  if (value == "depth_fit") return MeasurementSource::DepthFit;
  return std::nullopt;
}

bool is_measurement_source(std::string_view value) {
  return measurement_source_from_string(value).has_value();
}

}  // namespace toporoom::domain
