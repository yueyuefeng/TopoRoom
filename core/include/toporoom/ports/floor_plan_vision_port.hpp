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

struct VisionRequest {
  std::string image_uri;
  std::vector<std::uint8_t> image_bytes;
};

struct VisionResult {
  bool ok = false;
  std::string error;
  std::string adapter_id;
  std::vector<DetectedWall> walls;
  std::string room_name = "客厅";
};

// Floor-plan photo → wall centerlines. Does not write SceneIR; the app applies
// DetectedWalls through FloorPlanDocument commands (I1).
class FloorPlanVisionPort {
 public:
  virtual ~FloorPlanVisionPort() = default;
  virtual VisionResult detect_walls(const VisionRequest& request) = 0;
};

}  // namespace toporoom::ports
