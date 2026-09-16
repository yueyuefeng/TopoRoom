#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::ports {

FloorPlanSolidSemantics semantics_from_scene_ir(const domain::SceneIR& scene) {
  FloorPlanSolidSemantics out;
  out.document_id = scene.id;
  out.revision = scene.revision;
  for (const auto& storey : scene.storeys) {
    SolidStoreySemantics s;
    s.id = storey.id;
    s.height_mm = storey.height_mm;
    s.elevation_mm = storey.elevation_mm;
    for (const auto& wall : storey.walls) {
      SolidWallSemantics w;
      w.id = wall.id;
      w.start_x = wall.start.x;
      w.start_y = wall.start.y;
      w.end_x = wall.end.x;
      w.end_y = wall.end.y;
      w.thickness_mm = wall.thickness_mm;
      w.height_mm = wall.height_mm;
      for (const auto& opening : wall.openings) {
        w.openings.push_back(SolidOpeningSemantics{
            opening.id, opening.width_mm, opening.height_mm, opening.offset_mm,
            opening.sill_height_mm});
      }
      s.walls.push_back(std::move(w));
    }
    for (const auto& room : storey.rooms) {
      s.rooms.push_back(SolidRoomSemantics{room.id, room.wall_ids});
    }
    out.storeys.push_back(std::move(s));
  }
  return out;
}

}  // namespace toporoom::ports
