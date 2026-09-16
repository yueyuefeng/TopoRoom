#include <gtest/gtest.h>

#include "toporoom/adapters/export_scene_graph.hpp"
#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::adapters::export_gltf_json;
using toporoom::adapters::export_scene_graph;
using toporoom::adapters::FakeGeometryPort;
using toporoom::domain::AddOpeningProps;
using toporoom::domain::AddWallProps;
using toporoom::domain::CloseRoomProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::LengthMm;
using toporoom::domain::OpeningKind;
using toporoom::domain::PointMm;
using toporoom::domain::WallKind;
using toporoom::ports::BuildRequest;
using toporoom::ports::semantics_from_scene_ir;

namespace {

toporoom::domain::SceneIR sample_scene() {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_gltf"});
  const auto storey_id = doc.storeys()[0].id();
  auto add = [&](const char* id, double x0, double y0, double x1, double y1) {
    AddWallProps props;
    props.storey_id = storey_id;
    props.id = id;
    props.start = PointMm::of(x0, y0);
    props.end = PointMm::of(x1, y1);
    props.thickness = LengthMm::of(200);
    props.height = LengthMm::of(2800);
    props.kind = WallKind::Exterior;
    doc.add_wall(props);
  };
  add("wall_s", 0, 0, 4000, 0);
  AddOpeningProps opening;
  opening.storey_id = storey_id;
  opening.wall_id = "wall_s";
  opening.id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width = LengthMm::of(900);
  opening.height = LengthMm::of(2100);
  opening.offset_along_wall = LengthMm::of(800);
  doc.add_opening(opening);
  add("wall_e", 4000, 0, 4000, 3000);
  add("wall_n", 4000, 3000, 0, 3000);
  add("wall_w", 0, 3000, 0, 0);
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_living";
  room.wall_ids = {"wall_s", "wall_e", "wall_n", "wall_w"};
  doc.close_room(room);
  return doc.to_scene_ir();
}

}  // namespace

TEST(ExportSceneGraph, NamesNodesWithExtras) {
  const auto scene = sample_scene();
  FakeGeometryPort geometry;
  BuildRequest request;
  request.document_rev = scene.revision;
  request.semantics = semantics_from_scene_ir(scene);
  const auto rebuilt = geometry.rebuild(request);
  ASSERT_TRUE(rebuilt.ok);
  const auto graph = export_scene_graph(scene, rebuilt.meshes);
  bool storey = false, wall = false, room = false, opening = false;
  for (const auto& node : graph.nodes) {
    if (node.name == "Storey_" + scene.storeys[0].id) storey = true;
    if (node.name == "Wall_wall_s") wall = true;
    if (node.name == "Room_room_living") room = true;
    if (node.name == "Opening_op_door") opening = true;
    EXPECT_FALSE(node.toporoom_id.empty());
  }
  EXPECT_TRUE(storey);
  EXPECT_TRUE(wall);
  EXPECT_TRUE(room);
  EXPECT_TRUE(opening);
  EXPECT_EQ(graph.source_units, "mm");
  EXPECT_EQ(graph.units, "m");
}

TEST(ExportGltfJson, MinimalGltf2) {
  const auto scene = sample_scene();
  FakeGeometryPort geometry;
  BuildRequest request;
  request.semantics = semantics_from_scene_ir(scene);
  const auto rebuilt = geometry.rebuild(request);
  ASSERT_TRUE(rebuilt.ok);
  const auto gltf = export_gltf_json(scene, rebuilt.meshes);
  EXPECT_NE(gltf.find("\"version\":\"2.0\""), std::string::npos);
  EXPECT_NE(gltf.find("toporoom-compiler/"), std::string::npos);
  EXPECT_NE(gltf.find("Wall_wall_s"), std::string::npos);
  EXPECT_NE(gltf.find("\"kind\":\"storey\""), std::string::npos);
}
