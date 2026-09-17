#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/events.hpp"
#include "toporoom/domain/hosted_component.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/measurement.hpp"
#include "toporoom/domain/opening.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/domain/scene_ir.hpp"
#include "toporoom/domain/storey.hpp"
#include "toporoom/domain/wall.hpp"

namespace toporoom::domain {

// FloorPlanDocument = 方案 / 户型文档 (aggregate root). SceneIR is its serialization.
struct CreateFloorPlanProps {
  std::string id;
  std::optional<std::string> storey_id;
  std::optional<LengthMm> storey_height;
  std::optional<LengthMm> storey_elevation;
  std::optional<FaceDatum> face_datum;
  std::optional<std::string> scheme_label;

  explicit CreateFloorPlanProps(std::string document_id) : id(std::move(document_id)) {}
};

struct AddWallProps {
  std::string storey_id;
  std::optional<std::string> id;
  PointMm start = PointMm::of(0, 0);
  PointMm end = PointMm::of(1, 0);
  LengthMm thickness = LengthMm::of(1);
  LengthMm height = LengthMm::of(1);
  WallKind kind = WallKind::Exterior;
};

struct AddOpeningProps {
  std::string storey_id;
  std::string wall_id;
  std::optional<std::string> id;
  OpeningKind kind = OpeningKind::Door;
  LengthMm width = LengthMm::of(1);
  LengthMm height = LengthMm::of(1);
  LengthMm offset_along_wall = LengthMm::zero();
  LengthMm sill_height = LengthMm::zero();
};

struct CloseRoomProps {
  std::string storey_id;
  std::string id;
  std::vector<std::string> wall_ids;
  std::string name;
  SpaceType space_type = SpaceType::Interior;
  std::optional<LengthMm> clear_height;
};

struct SetMeasurementProps {
  std::string id;
  MeasurementKind kind = MeasurementKind::Length;
  LengthMm value = LengthMm::zero();
  MeasurementSource source = MeasurementSource::Typed;
  std::optional<std::string> instrument_id;
  std::vector<std::string> between;
  std::optional<MeasurementTarget> target;
};

struct PlaceHostedComponentProps {
  std::string storey_id;
  std::optional<std::string> id;
  HostedKind kind = HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
};

class FloorPlanDocument {
 public:
  static FloorPlanDocument create(CreateFloorPlanProps props);
  static FloorPlanDocument from_scene_ir(const SceneIR& scene);

  const std::string& format() const noexcept { return format_; }
  const std::string& version() const noexcept { return version_; }
  const std::string& units() const noexcept { return units_; }
  const std::string& id() const noexcept { return id_; }
  int revision() const noexcept { return revision_; }
  std::optional<FaceDatum> face_datum() const noexcept { return face_datum_; }
  const std::optional<std::string>& scheme_label() const noexcept { return scheme_label_; }
  const std::vector<Storey>& storeys() const noexcept { return storeys_; }
  const std::vector<Measurement>& measurements() const noexcept {
    return measurements_;
  }

  Wall add_wall(AddWallProps props);
  Opening add_opening(AddOpeningProps props);
  void close_room(CloseRoomProps props);
  void set_room_clear_height(const std::string& storey_id, const std::string& room_id,
                             LengthMm clear_height_mm);
  void set_storey_height(const std::string& storey_id, LengthMm height_mm,
                         bool follow_matching_walls = true);
  HostedComponent place_hosted_component(PlaceHostedComponentProps props);
  Measurement set_measurement(SetMeasurementProps props);
  SceneIR to_scene_ir() const;
  std::vector<DomainEvent> pull_domain_events();

 private:
  FloorPlanDocument(std::string id, int revision, std::vector<Storey> storeys,
                    std::vector<Measurement> measurements,
                    std::optional<FaceDatum> face_datum = std::nullopt,
                    std::optional<std::string> scheme_label = std::nullopt);

  void apply_measurement_target(const Measurement& measurement);
  void apply_storey_height(const std::string& storey_id, LengthMm height_mm,
                           bool follow_matching_walls);
  void resize_opening(const std::string& opening_id, LengthMm width);
  Storey& require_storey(const std::string& storey_id);
  const Storey& require_storey(const std::string& storey_id) const;
  void replace_storey(Storey storey);
  void bump_semantics();
  void record(DomainEvent event);
  std::string next_id(const std::string& prefix);

  std::string format_ = kSceneIrFormat;
  std::string version_ = kSceneIrVersion;
  std::string units_ = kSceneIrUnits;
  std::string id_;
  int revision_ = 0;
  std::optional<FaceDatum> face_datum_;
  std::optional<std::string> scheme_label_;
  std::vector<Storey> storeys_;
  std::vector<Measurement> measurements_;
  std::vector<DomainEvent> events_;
  int seq_ = 0;
};

}  // namespace toporoom::domain
