#include "toporoom/adapters/floor_plan_vision_adapters.hpp"

#include <fstream>
#include <string>

namespace toporoom::adapters {
namespace {

bool looks_like_filesystem_path(const std::string& uri) {
  if (uri.empty()) return false;
  if (uri.rfind("fixture:", 0) == 0) return false;
  if (uri.rfind("camera:", 0) == 0) return false;
  return uri.find('/') != std::string::npos || uri.find('\\') != std::string::npos;
}

bool file_readable(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  return static_cast<bool>(in);
}

}  // namespace

ports::VisionResult FakeVisionAdapter::detect_walls(const ports::VisionRequest& request) {
  if (looks_like_filesystem_path(request.image_uri) && request.image_bytes.empty() &&
      !file_readable(request.image_uri)) {
    ports::VisionResult out;
    out.ok = false;
    out.adapter_id = "fake";
    out.error = "image not found: " + request.image_uri;
    return out;
  }
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
