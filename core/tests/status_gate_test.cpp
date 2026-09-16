#include <gtest/gtest.h>

#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/app/export_app_service.hpp"
#include "toporoom/app/status_gate.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::adapters::FakeGeometryPort;
using toporoom::app::ExportAppService;
using toporoom::app::ExportRejectedError;
using toporoom::app::StatusGate;
using toporoom::domain::AddWallProps;
using toporoom::domain::CloseRoomProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::LengthMm;
using toporoom::domain::PointMm;
using toporoom::domain::WallKind;
using toporoom::ports::FaultCode;
using toporoom::ports::RebuildResult;

namespace {

toporoom::domain::SceneIR rectangular_scene() {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_export"});
  const auto storey_id = doc.storeys()[0].id();
  const struct {
    const char* id;
    double x0, y0, x1, y1;
  } walls[] = {
      {"wall_n", 0, 3000, 4000, 3000},
      {"wall_e", 4000, 3000, 4000, 0},
      {"wall_s", 4000, 0, 0, 0},
      {"wall_w", 0, 0, 0, 3000},
  };
  for (const auto& wall : walls) {
    AddWallProps props;
    props.storey_id = storey_id;
    props.id = wall.id;
    props.start = PointMm::of(wall.x0, wall.y0);
    props.end = PointMm::of(wall.x1, wall.y1);
    props.thickness = LengthMm::of(200);
    props.height = LengthMm::of(2800);
    props.kind = WallKind::Exterior;
    doc.add_wall(props);
  }
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_living";
  room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
  doc.close_room(room);
  return doc.to_scene_ir();
}

}  // namespace

TEST(StatusGate, RejectsFault) {
  StatusGate gate;
  RebuildResult result;
  result.ok = false;
  result.fault = {FaultCode::NotManifold, "non-manifold solid", {"wall_s"}};
  EXPECT_THROW(gate.assert_exportable(result), ExportRejectedError);
}

TEST(StatusGate, AllowsOk) {
  StatusGate gate;
  RebuildResult result;
  result.ok = true;
  EXPECT_NO_THROW(gate.assert_exportable(result));
}

TEST(ExportAppService, RefusesStructuralExportOnFault) {
  FakeGeometryPort geometry;
  geometry.fail_with({FaultCode::NotManifold, "broken boolean", {"wall_s"}});
  ExportAppService service(geometry);
  const auto outcome = service.export_scene_graph(rectangular_scene());
  EXPECT_FALSE(outcome.ok);
  EXPECT_EQ(outcome.fault.code, FaultCode::NotManifold);
  EXPECT_TRUE(outcome.glb.empty());
  EXPECT_NE(outcome.dxf.find("WALLS"), std::string::npos);
}

TEST(ExportAppService, ExportsNamedSceneGraphWhenOk) {
  FakeGeometryPort geometry;
  ExportAppService service(geometry);
  const auto outcome = service.export_scene_graph(rectangular_scene());
  ASSERT_TRUE(outcome.ok);
  bool storey = false, wall = false, room = false;
  for (const auto& node : outcome.graph.nodes) {
    if (node.name.rfind("Storey_", 0) == 0) storey = true;
    if (node.name.rfind("Wall_", 0) == 0) wall = true;
    if (node.name.rfind("Room_", 0) == 0) room = true;
  }
  EXPECT_TRUE(storey);
  EXPECT_TRUE(wall);
  EXPECT_TRUE(room);
}
