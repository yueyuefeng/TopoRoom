#pragma once

#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/measurement.hpp"

namespace toporoom::domain {

inline constexpr const char* kSceneIrFormat = "toporoom.sceneir";
inline constexpr const char* kSceneIrVersion = "0.1";
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
};

struct SceneIRStorey {
  std::string id;
  double elevation_mm = 0;
  double height_mm = 0;
  std::vector<SceneIRWall> walls;
  std::vector<SceneIRRoom> rooms;
};

struct SceneIR {
  std::string format = kSceneIrFormat;
  std::string version = kSceneIrVersion;
  std::string id;
  std::string units = kSceneIrUnits;
  int revision = 0;
  std::vector<SceneIRStorey> storeys;
  std::vector<Measurement> measurements;
};

}  // namespace toporoom::domain
