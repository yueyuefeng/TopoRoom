#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/measurement.hpp"

namespace toporoom::domain {

inline constexpr const char* kSceneIrFormat = "toporoom.sceneir";
// New writes are SceneIR 0.2 (additive). 0.1 files remain readable.
inline constexpr const char* kSceneIrVersion = "0.2";
inline constexpr const char* kSceneIrUnits = "mm";

struct SceneIRPoint {
  double x = 0;
  double y = 0;
};

struct SceneIROpening {
  std::string id;
  OpeningKind kind = OpeningKind::Door;
  double width_mm = 0;
  double height_mm = 0;
  double offset_mm = 0;
  double sill_height_mm = 0;
  WindowSubtype subtype = WindowSubtype::Unspecified;
};

struct SceneIRWall {
  std::string id;
  WallKind kind = WallKind::Exterior;
  SceneIRPoint start;
  SceneIRPoint end;
  double thickness_mm = 0;
  double height_mm = 0;
  std::vector<SceneIROpening> openings;
};

struct SceneIRRoom {
  std::string id;
  std::vector<std::string> wall_ids;
  std::string name;
  SpaceType space_type = SpaceType::Interior;
  std::optional<double> clear_height_mm;
};

struct SceneIRHostedComponent {
  std::string id;
  HostedKind kind = HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
  std::optional<std::string> host_wall_id;
};

struct SceneIRStorey {
  std::string id;
  double elevation_mm = 0;
  // height_mm is 层高, never 室内净高.
  double height_mm = 0;
  std::vector<SceneIRWall> walls;
  std::vector<SceneIRRoom> rooms;
  std::vector<SceneIRHostedComponent> hosted_components;
};

struct SceneIRMeta {
  std::optional<FaceDatum> face_datum;
  std::optional<std::string> scheme_label;
};

struct SceneIR {
  std::string format = kSceneIrFormat;
  std::string version = kSceneIrVersion;
  std::string id;
  std::string units = kSceneIrUnits;
  int revision = 0;
  SceneIRMeta meta;
  std::vector<SceneIRStorey> storeys;
  std::vector<Measurement> measurements;
};

}  // namespace toporoom::domain
