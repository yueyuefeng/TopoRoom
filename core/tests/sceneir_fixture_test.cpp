#include <fstream>
#include <sstream>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif

using toporoom::adapters::load_scene_ir_file;
using toporoom::adapters::validate_scene_ir_json;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::MeasurementSource;

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

TEST(SceneIrFixture, RejectsForbiddenSource) {
  auto text = read_file(fixture_path());
  const auto pos = text.find("\"laser\"");
  ASSERT_NE(pos, std::string::npos);
  text.replace(pos, 7, "\"rf_ble\"");
  const auto issues = validate_scene_ir_json(text);
  ASSERT_FALSE(issues.empty());
  EXPECT_NE(issues[0].find("source"), std::string::npos);
}
