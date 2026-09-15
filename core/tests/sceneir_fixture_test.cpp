#include <fstream>
#include <sstream>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/export_scene_graph.hpp"
#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/ports/geometry_port.hpp"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif

using toporoom::adapters::export_scene_graph;
using toporoom::adapters::FakeGeometryPort;
using toporoom::adapters::load_scene_ir_file;
using toporoom::adapters::validate_scene_ir_json;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::MeasurementSource;
using toporoom::ports::BuildRequest;
using toporoom::ports::semantics_from_scene_ir;

namespace {

std::string fixture_path() {
  return std::string(TOPOROOM_FIXTURE_DIR) + "/rect-room-door-laser.sceneir.json";
}

std::string read_file(const std::string& path) {
  std::ifstream in(path);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return buffer.str();
}

}  // namespace

TEST(SceneIrFixture, LoadsAndValidates) {
  const auto text = read_file(fixture_path());
  EXPECT_TRUE(validate_scene_ir_json(text).empty());
  const auto scene = load_scene_ir_file(fixture_path());
  EXPECT_EQ(scene.format, "toporoom.sceneir");
  EXPECT_EQ(scene.version, "0.1");
  EXPECT_EQ(scene.units, "mm");
  EXPECT_EQ(scene.storeys[0].rooms[0].id, "room_living");
  EXPECT_EQ(scene.measurements[0].source, MeasurementSource::Laser);
}

TEST(SceneIrFixture, ReconstitutesDocument) {
  const auto scene = load_scene_ir_file(fixture_path());
  const auto document = FloorPlanDocument::from_scene_ir(scene);
  EXPECT_EQ(document.storeys()[0].rooms()[0].id(), "room_living");
  EXPECT_EQ(document.measurements()[0].source, MeasurementSource::Laser);
  EXPECT_EQ(document.to_scene_ir().storeys[0].walls.size(), 4u);
}

TEST(SceneIrFixture, ExportsNodeNames) {
  const auto scene = load_scene_ir_file(fixture_path());
  FakeGeometryPort geometry;
  BuildRequest request;
  request.semantics = semantics_from_scene_ir(scene);
  const auto rebuilt = geometry.rebuild(request);
  ASSERT_TRUE(rebuilt.ok);
  const auto graph = export_scene_graph(scene, rebuilt.meshes);
  std::string joined;
  for (const auto& node : graph.nodes) {
    joined += node.name + ";";
  }
  EXPECT_NE(joined.find("Storey_storey_1"), std::string::npos);
  EXPECT_NE(joined.find("Wall_wall_s"), std::string::npos);
  EXPECT_NE(joined.find("Room_room_living"), std::string::npos);
  EXPECT_NE(joined.find("Opening_op_door"), std::string::npos);
}

TEST(SceneIrFixture, RejectsForbiddenSource) {
  auto text = read_file(fixture_path());
  const auto pos = text.find("\"laser\"");
  ASSERT_NE(pos, std::string::npos);
  text.replace(pos, 7, "\"rf_ble\"");
  const auto issues = validate_scene_ir_json(text);
  ASSERT_FALSE(issues.empty());
  EXPECT_NE(issues[0].find("source"), std::string::npos);
}
