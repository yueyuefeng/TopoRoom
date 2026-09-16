#include <cmath>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/manifold_geometry_port.hpp"
#include "toporoom/app/export_app_service.hpp"
#include "toporoom/app/status_gate.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::adapters::ManifoldGeometryPort;
using toporoom::app::ExportAppService;
using toporoom::app::StatusGate;
using toporoom::domain::AddOpeningProps;
using toporoom::domain::AddWallProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::LengthMm;
using toporoom::domain::OpeningKind;
using toporoom::domain::PointMm;
using toporoom::domain::SceneIR;
using toporoom::domain::WallKind;
using toporoom::ports::BuildRequest;
using toporoom::ports::FaultCode;
using toporoom::ports::MeshSolid;
using toporoom::ports::semantics_from_scene_ir;
using toporoom::ports::SolidStoreySemantics;
using toporoom::ports::SolidWallSemantics;

namespace {

constexpr double kWallLengthMm = 4000;
constexpr double kWallThicknessMm = 200;
constexpr double kWallHeightMm = 2800;
constexpr double kOpeningWidthMm = 900;
constexpr double kOpeningHeightMm = 2100;
constexpr double kOpeningOffsetMm = 800;

double solid_volume_mm3(double length, double thickness, double height) {
  return length * thickness * height;
}

double max_abs_vertex(const MeshSolid& solid) {
  double peak = 0;
  for (double v : solid.vertices_mm) {
    peak = std::max(peak, std::abs(v));
  }
  return peak;
}

const MeshSolid* wall_solid(const toporoom::ports::RebuildResult& result,
                            const std::string& wall_id) {
  for (const auto& solid : result.meshes.solids) {
    if (solid.kind == "wall" && solid.entity_id == wall_id) return &solid;
  }
  return nullptr;
}

SceneIR single_wall_scene(bool with_opening) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_manifold"});
  const auto storey_id = doc.storeys()[0].id();
  AddWallProps wall;
  wall.storey_id = storey_id;
  wall.id = "wall_s";
  wall.start = PointMm::of(0, 0);
  wall.end = PointMm::of(kWallLengthMm, 0);
  wall.thickness = LengthMm::of(kWallThicknessMm);
  wall.height = LengthMm::of(kWallHeightMm);
  wall.kind = WallKind::Exterior;
  doc.add_wall(wall);
  if (with_opening) {
    AddOpeningProps opening;
    opening.storey_id = storey_id;
    opening.wall_id = "wall_s";
    opening.id = "op_door";
    opening.kind = OpeningKind::Door;
    opening.width = LengthMm::of(kOpeningWidthMm);
    opening.height = LengthMm::of(kOpeningHeightMm);
    opening.offset_along_wall = LengthMm::of(kOpeningOffsetMm);
    doc.add_opening(opening);
  }
  return doc.to_scene_ir();
}

BuildRequest request_for(const SceneIR& scene) {
  BuildRequest request;
  request.document_rev = scene.revision;
  request.rebuild_generation = 1;
  request.dirty = true;
  request.semantics = semantics_from_scene_ir(scene);
  return request;
}

BuildRequest degenerate_wall_request() {
  BuildRequest request;
  request.document_rev = 1;
  request.rebuild_generation = 1;
  request.dirty = true;
  request.semantics.document_id = "doc_bad";
  SolidStoreySemantics storey;
  storey.id = "storey_1";
  storey.height_mm = kWallHeightMm;
  SolidWallSemantics wall;
  wall.id = "wall_empty";
  wall.start_x = 0;
  wall.start_y = 0;
  wall.end_x = 0;
  wall.end_y = 0;
  wall.thickness_mm = 0;
  wall.height_mm = 0;
  storey.walls.push_back(std::move(wall));
  request.semantics.storeys.push_back(std::move(storey));
  return request;
}

}  // namespace

TEST(ManifoldGeometryPort, ExtrudesRectangularWallWithVolume) {
  ManifoldGeometryPort port;
  const auto result = port.rebuild(request_for(single_wall_scene(false)));
  ASSERT_TRUE(result.ok) << result.fault.message;
  const auto* solid = wall_solid(result, "wall_s");
  ASSERT_NE(solid, nullptr);
  EXPECT_EQ(solid->node_hint, "Wall_wall_s");
  EXPECT_FALSE(solid->vertices_mm.empty());
  EXPECT_FALSE(solid->indices.empty());
  EXPECT_EQ(solid->indices.size() % 3, 0u);
  const double expected = solid_volume_mm3(kWallLengthMm, kWallThicknessMm, kWallHeightMm);
  EXPECT_NEAR(solid->volume_mm3, expected, expected * 0.02);
  EXPECT_GT(solid->volume_mm3, 0.0);
}

TEST(ManifoldGeometryPort, BooleanOpeningReducesVolume) {
  ManifoldGeometryPort port;
  const auto solid_wall = port.rebuild(request_for(single_wall_scene(false)));
  const auto holed_wall = port.rebuild(request_for(single_wall_scene(true)));
  ASSERT_TRUE(solid_wall.ok);
  ASSERT_TRUE(holed_wall.ok) << holed_wall.fault.message;
  const auto* before = wall_solid(solid_wall, "wall_s");
  const auto* after = wall_solid(holed_wall, "wall_s");
  ASSERT_NE(before, nullptr);
  ASSERT_NE(after, nullptr);
  const double hole = solid_volume_mm3(kOpeningWidthMm, kWallThicknessMm, kOpeningHeightMm);
  EXPECT_LT(after->volume_mm3, before->volume_mm3);
  EXPECT_NEAR(before->volume_mm3 - after->volume_mm3, hole, hole * 0.05);
}

TEST(ManifoldGeometryPort, VerticesStayMillimetresUntilExport) {
  ManifoldGeometryPort port;
  const auto result = port.rebuild(request_for(single_wall_scene(false)));
  ASSERT_TRUE(result.ok);
  const auto* solid = wall_solid(result, "wall_s");
  ASSERT_NE(solid, nullptr);
  const double peak = max_abs_vertex(*solid);
  // 4000 mm wall must not be converted to metres (peak ≈ 4) here.
  EXPECT_GT(peak, 1000.0);
  EXPECT_LT(peak, 10000.0);
}

TEST(ManifoldGeometryPort, EmptySectionIsFault) {
  ManifoldGeometryPort port;
  const auto result = port.rebuild(degenerate_wall_request());
  EXPECT_FALSE(result.ok);
  EXPECT_EQ(result.fault.code, FaultCode::InvalidGeometry);
  EXPECT_EQ(port.status(std::nullopt, std::nullopt),
            toporoom::ports::GeometryStatus::Fault);
}

TEST(ManifoldGeometryPort, OpeningOutOfBoundsIsFault) {
  ManifoldGeometryPort port;
  auto request = request_for(single_wall_scene(false));
  ASSERT_FALSE(request.semantics.storeys.empty());
  ASSERT_FALSE(request.semantics.storeys[0].walls.empty());
  request.semantics.storeys[0].walls[0].openings.push_back(
      {"op_oob", 900, 2100, 5000, 0});
  const auto result = port.rebuild(request);
  EXPECT_FALSE(result.ok);
  EXPECT_EQ(result.fault.code, FaultCode::OpeningOutOfBounds);
}

TEST(ManifoldGeometryPort, StatusGateRejectsFaultOnStructuralExport) {
  ManifoldGeometryPort port;
  ExportAppService service(port);
  StatusGate gate;
  const auto rebuilt = port.rebuild(degenerate_wall_request());
  EXPECT_THROW(gate.assert_exportable(rebuilt), toporoom::app::ExportRejectedError);

  SceneIR empty;
  empty.id = "doc_bad";
  empty.revision = 1;
  empty.storeys.push_back({});
  empty.storeys[0].id = "storey_1";
  empty.storeys[0].walls.push_back({});
  empty.storeys[0].walls[0].id = "wall_empty";
  const auto outcome = service.export_scene_graph(empty);
  EXPECT_FALSE(outcome.ok);
  EXPECT_EQ(outcome.fault.code, FaultCode::InvalidGeometry);
}

TEST(ManifoldGeometryPort, RebuildAndExportGateAllowOkSolids) {
  ManifoldGeometryPort port;
  ExportAppService service(port);
  const auto scene = single_wall_scene(true);
  const auto outcome = service.export_scene_graph(scene);
  ASSERT_TRUE(outcome.ok) << outcome.fault.message;
  const MeshSolid* solid = nullptr;
  for (const auto& candidate : outcome.meshes.solids) {
    if (candidate.kind == "wall" && candidate.entity_id == "wall_s") {
      solid = &candidate;
      break;
    }
  }
  ASSERT_NE(solid, nullptr);
  EXPECT_GT(solid->volume_mm3, 0.0);
  bool wall_node = false;
  bool opening_node = false;
  for (const auto& node : outcome.graph.nodes) {
    if (node.name == "Wall_wall_s") wall_node = true;
    if (node.name == "Opening_op_door") opening_node = true;
  }
  EXPECT_TRUE(wall_node);
  EXPECT_TRUE(opening_node);
}
