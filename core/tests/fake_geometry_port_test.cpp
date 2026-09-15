#include <gtest/gtest.h>

#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::adapters::FakeGeometryPort;
using toporoom::ports::BuildRequest;
using toporoom::ports::FaultCode;
using toporoom::ports::FloorPlanSolidSemantics;
using toporoom::ports::semantics_from_scene_ir;
using toporoom::domain::SceneIR;
using toporoom::domain::SceneIRStorey;
using toporoom::domain::SceneIRWall;

TEST(FakeGeometryPort, ReturnsOkMeshWithWallHint) {
  SceneIR scene;
  scene.id = "doc_fake";
  scene.revision = 1;
  SceneIRStorey storey;
  storey.id = "storey_1";
  storey.height_mm = 2800;
  SceneIRWall wall;
  wall.id = "wall_s";
  wall.start = {0, 0};
  wall.end = {1000, 0};
  wall.thickness_mm = 200;
  wall.height_mm = 2800;
  storey.walls.push_back(wall);
  scene.storeys.push_back(storey);

  FakeGeometryPort port;
  BuildRequest request;
  request.document_rev = 1;
  request.rebuild_generation = 1;
  request.semantics = semantics_from_scene_ir(scene);
  const auto result = port.rebuild(request);
  ASSERT_TRUE(result.ok);
  ASSERT_FALSE(result.meshes.solids.empty());
  EXPECT_EQ(result.meshes.solids[0].node_hint, "Wall_wall_s");
}

TEST(FakeGeometryPort, ReturnsFaultWhenInstructed) {
  FakeGeometryPort port;
  port.fail_with({FaultCode::InvalidGeometry, "boom", {"wall_s"}});
  BuildRequest request;
  request.semantics.document_id = "doc_fake";
  const auto result = port.rebuild(request);
  EXPECT_FALSE(result.ok);
  EXPECT_EQ(result.fault.code, FaultCode::InvalidGeometry);
  EXPECT_EQ(result.fault.message, "boom");
}
