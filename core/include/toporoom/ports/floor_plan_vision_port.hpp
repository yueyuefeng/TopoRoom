#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"

namespace toporoom::ports {

struct DetectedWall {
  std::string id;
  double start_x = 0;
  double start_y = 0;
  double end_x = 0;
  double end_y = 0;
  double thickness_mm = 200;
  double height_mm = 2800;
  domain::WallKind kind = domain::WallKind::Masonry;
};

struct DetectedOpening {
  std::string id;
  domain::OpeningKind kind = domain::OpeningKind::Door;
  domain::WindowSubtype subtype = domain::WindowSubtype::Unspecified;
  double center_x = 0;
  double center_y = 0;
  double width_mm = 900;
  double height_mm = 2100;
  double sill_mm = 0;
  double along_x = 1;
  double along_y = 0;
};

struct DetectedColumn {
  std::string id;
  double center_x = 0;
  double center_y = 0;
  double width_mm = 240;
  double depth_mm = 240;
};

struct VisionRequest {
  std::string image_uri;
  std::vector<std::uint8_t> image_bytes;
};

struct VisionResult {
  bool ok = false;
  std::string error;
  std::string adapter_id;
  std::vector<DetectedWall> walls;
  std::vector<DetectedOpening> openings;
  std::vector<DetectedColumn> columns;
  std::string room_name = "客厅";
  double mm_per_px = 0;
  int shear_count = 0;
  int masonry_count = 0;
};

// Floor-plan photo → wall centerlines. Does not write SceneIR; the app applies
// DetectedWalls through FloorPlanDocument commands (I1).
class FloorPlanVisionPort {
 public:
  virtual ~FloorPlanVisionPort() = default;
  virtual VisionResult detect_walls(const VisionRequest& request) = 0;
};

}  // namespace toporoom::ports
