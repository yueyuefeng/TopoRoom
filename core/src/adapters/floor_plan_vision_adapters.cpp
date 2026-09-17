#include "toporoom/adapters/floor_plan_vision_adapters.hpp"

namespace toporoom::adapters {

ports::VisionResult FakeVisionAdapter::detect_walls(const ports::VisionRequest&) {
  ports::VisionResult out;
  out.ok = true;
  out.adapter_id = "fake";
  out.room_name = "客厅";
  // 4000×3000 一室: 四边承重/剪力墙 + 中部砌体隔墙.
  out.walls = {
      {"wall_n", 0, 3000, 4000, 3000, 200, 2800, domain::WallKind::ShearWall},
      {"wall_e", 4000, 3000, 4000, 0, 200, 2800, domain::WallKind::ShearWall},
      {"wall_s", 4000, 0, 0, 0, 200, 2800, domain::WallKind::ShearWall},
      {"wall_w", 0, 0, 0, 3000, 200, 2800, domain::WallKind::ShearWall},
      {"wall_p", 2000, 0, 2000, 3000, 120, 2800, domain::WallKind::Masonry},
  };
  return out;
}

ports::VisionResult OnDeviceMlVisionAdapter::detect_walls(const ports::VisionRequest&) {
  ports::VisionResult out;
  out.ok = false;
  out.adapter_id = "on_device_ml";
  out.error = "on-device ML not linked";
  return out;
}

}  // namespace toporoom::adapters
