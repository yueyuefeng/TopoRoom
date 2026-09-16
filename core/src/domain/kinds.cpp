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
    case WallKind::Masonry:
      return "masonry";
    case WallKind::ShearWall:
      return "shearWall";
  }
  return "unknown";
}

const char* to_string(OpeningKind kind) {
  switch (kind) {
    case OpeningKind::Door:
      return "door";
    case OpeningKind::Window:
      return "window";
    case OpeningKind::Archway:
      return "archway";
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

const char* to_string(FaceDatum datum) {
  switch (datum) {
    case FaceDatum::Structural:
      return "structural";
    case FaceDatum::Architectural:
      return "architectural";
    case FaceDatum::Finished:
      return "finished";
  }
  return "unknown";
}

const char* to_string(SpaceType space_type) {
  switch (space_type) {
    case SpaceType::Interior:
      return "interior";
    case SpaceType::Balcony:
      return "balcony";
    case SpaceType::Exterior:
      return "exterior";
  }
  return "unknown";
}

const char* to_string(HostedKind kind) {
  switch (kind) {
    case HostedKind::Beam:
      return "beam";
    case HostedKind::Column:
      return "column";
    case HostedKind::Flue:
      return "flue";
  }
  return "unknown";
}

std::optional<WallKind> wall_kind_from_string(std::string_view value) {
  if (value == "exterior") return WallKind::Exterior;
  if (value == "interior") return WallKind::Interior;
  if (value == "partition") return WallKind::Partition;
  if (value == "masonry") return WallKind::Masonry;
  if (value == "shearWall" || value == "shear_wall") return WallKind::ShearWall;
  return std::nullopt;
}

std::optional<OpeningKind> opening_kind_from_string(std::string_view value) {
  if (value == "door") return OpeningKind::Door;
  if (value == "window") return OpeningKind::Window;
  if (value == "archway") return OpeningKind::Archway;
  return std::nullopt;
}

std::optional<MeasurementSource> measurement_source_from_string(
    std::string_view value) {
  if (value == "laser") return MeasurementSource::Laser;
  if (value == "typed") return MeasurementSource::Typed;
  if (value == "depth_fit") return MeasurementSource::DepthFit;
  return std::nullopt;
}

std::optional<FaceDatum> face_datum_from_string(std::string_view value) {
  if (value == "structural") return FaceDatum::Structural;
  if (value == "architectural") return FaceDatum::Architectural;
  if (value == "finished") return FaceDatum::Finished;
  return std::nullopt;
}

std::optional<SpaceType> space_type_from_string(std::string_view value) {
  if (value == "interior") return SpaceType::Interior;
  if (value == "balcony") return SpaceType::Balcony;
  if (value == "exterior") return SpaceType::Exterior;
  return std::nullopt;
}

std::optional<HostedKind> hosted_kind_from_string(std::string_view value) {
  if (value == "beam") return HostedKind::Beam;
  if (value == "column") return HostedKind::Column;
  if (value == "flue") return HostedKind::Flue;
  return std::nullopt;
}

bool is_measurement_source(std::string_view value) {
  return measurement_source_from_string(value).has_value();
}

bool is_scene_ir_version_supported(std::string_view value) {
  return value == "0.1" || value == "0.1.0" || value == "0.2" || value == "0.2.0";
}

}  // namespace toporoom::domain
