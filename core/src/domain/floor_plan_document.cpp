#include "toporoom/domain/floor_plan_document.hpp"

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/room.hpp"

namespace toporoom::domain {
namespace {

constexpr const char* kDefaultStoreyId = "storey_1";
constexpr double kDefaultStoreyHeightMm = 2800;

void assert_measurement_may_replace(const Measurement& existing,
                                    const Measurement& next) {
  if (existing.source == MeasurementSource::Laser &&
      next.source == MeasurementSource::DepthFit) {
    throw DomainError(
        "depth_fit must not silently overwrite a laser measurement",
        "MEASUREMENT_SOURCE_LOCKED");
  }
  if (existing.source == MeasurementSource::Typed &&
      next.source == MeasurementSource::DepthFit) {
    throw DomainError(
        "depth_fit must not silently overwrite a typed measurement",
        "MEASUREMENT_SOURCE_LOCKED");
  }
}

}  // namespace

FloorPlanDocument::FloorPlanDocument(std::string id, int revision,
                                     std::vector<Storey> storeys,
                                     std::vector<Measurement> measurements,
                                     std::optional<FaceDatum> face_datum,
                                     std::optional<std::string> scheme_label)
    : format_(kSceneIrFormat),
      version_(kSceneIrVersion),
      units_(kSceneIrUnits),
      id_(std::move(id)),
      revision_(revision),
      face_datum_(face_datum),
      scheme_label_(std::move(scheme_label)),
      storeys_(std::move(storeys)),
      measurements_(std::move(measurements)) {}

FloorPlanDocument FloorPlanDocument::create(CreateFloorPlanProps props) {
  StoreyProps storey;
  storey.id = props.storey_id.value_or(kDefaultStoreyId);
  storey.elevation = props.storey_elevation.value_or(LengthMm::zero());
  storey.height = props.storey_height.value_or(LengthMm::of(kDefaultStoreyHeightMm));
  return FloorPlanDocument(std::move(props.id), 0, {Storey::create(std::move(storey))},
                           {}, props.face_datum, props.scheme_label);
}

FloorPlanDocument FloorPlanDocument::from_scene_ir(const SceneIR& scene) {
  if (scene.format != kSceneIrFormat) {
    throw DomainError("Unsupported SceneIR format: " + scene.format, "INVALID_SCENEIR");
  }
  if (!is_scene_ir_version_supported(scene.version)) {
    throw DomainError("Unsupported SceneIR version: " + scene.version,
                      "INVALID_SCENEIR");
  }
  if (scene.units != kSceneIrUnits) {
    throw DomainError("SceneIR units must be mm, got " + scene.units,
                      "INVALID_SCENEIR");
  }
  std::vector<Storey> storeys;
  storeys.reserve(scene.storeys.size());
  for (const auto& storey_ir : scene.storeys) {
    StoreyProps storey_props;
    storey_props.id = storey_ir.id;
    storey_props.elevation = LengthMm::of(storey_ir.elevation_mm);
    storey_props.height = LengthMm::of(storey_ir.height_mm);
    for (const auto& wall_ir : storey_ir.walls) {
      WallProps wall_props;
      wall_props.id = wall_ir.id;
      wall_props.kind = wall_ir.kind;
      wall_props.start = PointMm::of(wall_ir.start.x, wall_ir.start.y);
      wall_props.end = PointMm::of(wall_ir.end.x, wall_ir.end.y);
      wall_props.thickness = LengthMm::of(wall_ir.thickness_mm);
      wall_props.height = LengthMm::of(wall_ir.height_mm);
      for (const auto& opening_ir : wall_ir.openings) {
        OpeningProps opening_props;
        opening_props.id = opening_ir.id;
        opening_props.kind = opening_ir.kind;
        opening_props.width = LengthMm::of(opening_ir.width_mm);
        opening_props.height = LengthMm::of(opening_ir.height_mm);
        opening_props.offset_along_wall = LengthMm::of(opening_ir.offset_mm);
        opening_props.sill_height = LengthMm::of(opening_ir.sill_height_mm);
        wall_props.openings.push_back(Opening::create(std::move(opening_props)));
      }
      storey_props.walls.push_back(Wall::create(std::move(wall_props)));
    }
    for (const auto& room_ir : storey_ir.rooms) {
      std::optional<LengthMm> clear;
      if (room_ir.clear_height_mm) {
        clear = LengthMm::of(*room_ir.clear_height_mm);
      }
      storey_props.rooms.emplace_back(room_ir.id, room_ir.wall_ids, room_ir.name,
                                      room_ir.space_type, clear);
    }
    for (const auto& hosted : storey_ir.hosted_components) {
      storey_props.hosted_components.push_back(
          HostedComponent{hosted.id, hosted.kind, hosted.z_bottom_mm, hosted.depth_mm});
    }
    storeys.push_back(Storey::create(std::move(storey_props)));
  }
  return FloorPlanDocument(scene.id, scene.revision, std::move(storeys),
                           scene.measurements, scene.meta.face_datum,
                           scene.meta.scheme_label);
}

Wall FloorPlanDocument::add_wall(AddWallProps props) {
  Storey storey = require_storey(props.storey_id);
  WallProps wall_props;
  wall_props.id = props.id.value_or(next_id("wall"));
  wall_props.start = props.start;
  wall_props.end = props.end;
  wall_props.thickness = props.thickness;
  wall_props.height = props.height;
  wall_props.kind = props.kind;
  Wall wall = Wall::create(std::move(wall_props));
  replace_storey(storey.add_wall(wall));
  record(WallAdded{id_, props.storey_id, wall.id()});
  bump_semantics();
  return wall;
}

Opening FloorPlanDocument::add_opening(AddOpeningProps props) {
  Storey storey = require_storey(props.storey_id);
  OpeningProps opening_props;
  opening_props.id = props.id.value_or(next_id("opening"));
  opening_props.kind = props.kind;
  opening_props.width = props.width;
  opening_props.height = props.height;
  opening_props.offset_along_wall = props.offset_along_wall;
  opening_props.sill_height = props.sill_height;
  Opening opening = Opening::create(std::move(opening_props));
  replace_storey(storey.host_opening(props.wall_id, opening));
  record(OpeningAdded{id_, props.storey_id, props.wall_id, opening.id(), opening.kind()});
  bump_semantics();
  return opening;
}

void FloorPlanDocument::close_room(CloseRoomProps props) {
  Storey storey = require_storey(props.storey_id);
  Room room(props.id, props.wall_ids, props.name, props.space_type, props.clear_height);
  replace_storey(storey.close_room(room));
  record(RoomClosed{id_, props.storey_id, props.id, props.wall_ids});
  bump_semantics();
}

void FloorPlanDocument::set_room_clear_height(const std::string& storey_id,
                                              const std::string& room_id,
                                              LengthMm clear_height_mm) {
  Storey storey = require_storey(storey_id);
  bool found = false;
  for (const auto& room : storey.rooms()) {
    if (room.id() != room_id) continue;
    replace_storey(storey.replace_room(room.with_clear_height(clear_height_mm)));
    record(RoomAttributesChanged{id_, storey_id, room_id});
    bump_semantics();
    found = true;
    break;
  }
  if (!found) {
    throw DomainError("Room " + room_id + " not found", "ROOM_NOT_FOUND");
  }
}

void FloorPlanDocument::set_storey_height(const std::string& storey_id, LengthMm height_mm,
                                          bool follow_matching_walls) {
  apply_storey_height(storey_id, height_mm, follow_matching_walls);
  bump_semantics();
}

void FloorPlanDocument::apply_storey_height(const std::string& storey_id, LengthMm height_mm,
                                            bool follow_matching_walls) {
  Storey storey = require_storey(storey_id);
  replace_storey(storey.with_height(height_mm, follow_matching_walls));
  record(StoreyHeightChanged{id_, storey_id, height_mm.value()});
}

HostedComponent FloorPlanDocument::place_hosted_component(PlaceHostedComponentProps props) {
  Storey storey = require_storey(props.storey_id);
  HostedComponent component;
  component.id = props.id.value_or(next_id("hc"));
  component.kind = props.kind;
  component.z_bottom_mm = props.z_bottom_mm;
  component.depth_mm = props.depth_mm;
  replace_storey(storey.place_hosted_component(component));
  record(HostedComponentPlaced{id_, props.storey_id, component.id, component.kind});
  bump_semantics();
  return component;
}

Measurement FloorPlanDocument::set_measurement(SetMeasurementProps props) {
  Measurement next;
  next.id = props.id;
  next.kind = props.kind;
  next.value_mm = props.value.value();
  next.source = props.source;
  next.instrument_id = props.instrument_id;
  next.between = props.between;
  next.target = props.target;

  bool replaced = false;
  for (auto& existing : measurements_) {
    if (existing.id == next.id) {
      assert_measurement_may_replace(existing, next);
      existing = next;
      replaced = true;
      break;
    }
  }
  if (!replaced) {
    measurements_.push_back(next);
  }
  apply_measurement_target(next);
  bump_semantics();
  return next;
}

SceneIR FloorPlanDocument::to_scene_ir() const {
  SceneIR scene;
  scene.format = format_;
  scene.version = kSceneIrVersion;
  scene.id = id_;
  scene.units = units_;
  scene.revision = revision_;
  scene.meta.face_datum = face_datum_;
  scene.meta.scheme_label = scheme_label_;
  for (const auto& storey : storeys_) {
    SceneIRStorey storey_ir;
    storey_ir.id = storey.id();
    storey_ir.elevation_mm = storey.elevation().value();
    storey_ir.height_mm = storey.height().value();
    for (const auto& wall : storey.walls()) {
      SceneIRWall wall_ir;
      wall_ir.id = wall.id();
      wall_ir.kind = wall.kind();
      wall_ir.start = {wall.start().x(), wall.start().y()};
      wall_ir.end = {wall.end().x(), wall.end().y()};
      wall_ir.thickness_mm = wall.thickness().value();
      wall_ir.height_mm = wall.height().value();
      for (const auto& opening : wall.openings()) {
        SceneIROpening opening_ir;
        opening_ir.id = opening.id();
        opening_ir.kind = opening.kind();
        opening_ir.width_mm = opening.width().value();
        opening_ir.height_mm = opening.height().value();
        opening_ir.offset_mm = opening.offset_along_wall().value();
        opening_ir.sill_height_mm = opening.sill_height().value();
        wall_ir.openings.push_back(std::move(opening_ir));
      }
      storey_ir.walls.push_back(std::move(wall_ir));
    }
    for (const auto& room : storey.rooms()) {
      SceneIRRoom room_ir;
      room_ir.id = room.id();
      room_ir.wall_ids = room.wall_ids();
      room_ir.name = room.name();
      room_ir.space_type = room.space_type();
      if (room.clear_height()) {
        room_ir.clear_height_mm = room.clear_height()->value();
      }
      storey_ir.rooms.push_back(std::move(room_ir));
    }
    for (const auto& hosted : storey.hosted_components()) {
      storey_ir.hosted_components.push_back(
          SceneIRHostedComponent{hosted.id, hosted.kind, hosted.z_bottom_mm,
                                 hosted.depth_mm});
    }
    scene.storeys.push_back(std::move(storey_ir));
  }
  scene.measurements = measurements_;
  return scene;
}

std::vector<DomainEvent> FloorPlanDocument::pull_domain_events() {
  std::vector<DomainEvent> pending;
  pending.swap(events_);
  return pending;
}

void FloorPlanDocument::apply_measurement_target(const Measurement& measurement) {
  if (!measurement.target) return;
  const auto& target = *measurement.target;
  if ((target.entity_type == "opening" && target.field == "width") ||
      target.entity_type == "openingWidth") {
    resize_opening(target.entity_id, LengthMm::of(measurement.value_mm));
    return;
  }
  if ((target.entity_type == "storey" && target.field == "height") ||
      target.entity_type == "storeyHeight") {
    apply_storey_height(target.entity_id, LengthMm::of(measurement.value_mm), true);
  }
}

void FloorPlanDocument::resize_opening(const std::string& opening_id, LengthMm width) {
  for (const auto& storey : storeys_) {
    for (const auto& wall : storey.walls()) {
      for (const auto& opening : wall.openings()) {
        if (opening.id() != opening_id) continue;
        replace_storey(storey.replace_wall(wall.replace_opening(opening.with_width(width))));
        return;
      }
    }
  }
  throw DomainError("Opening " + opening_id + " not found", "OPENING_NOT_FOUND");
}

Storey& FloorPlanDocument::require_storey(const std::string& storey_id) {
  for (auto& storey : storeys_) {
    if (storey.id() == storey_id) return storey;
  }
  throw DomainError("Storey " + storey_id + " not found", "STOREY_NOT_FOUND");
}

const Storey& FloorPlanDocument::require_storey(const std::string& storey_id) const {
  for (const auto& storey : storeys_) {
    if (storey.id() == storey_id) return storey;
  }
  throw DomainError("Storey " + storey_id + " not found", "STOREY_NOT_FOUND");
}

void FloorPlanDocument::replace_storey(Storey storey) {
  for (auto& existing : storeys_) {
    if (existing.id() == storey.id()) {
      existing = std::move(storey);
      return;
    }
  }
  throw DomainError("Storey " + storey.id() + " not found", "STOREY_NOT_FOUND");
}

void FloorPlanDocument::bump_semantics() {
  revision_ += 1;
  record(FloorPlanSemanticsChanged{id_, revision_});
}

void FloorPlanDocument::record(DomainEvent event) { events_.push_back(std::move(event)); }

std::string FloorPlanDocument::next_id(const std::string& prefix) {
  seq_ += 1;
  return prefix + "_" + std::to_string(seq_);
}

}  // namespace toporoom::domain
