#include <optional>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif

using toporoom::adapters::load_scene_ir_file;
using toporoom::adapters::load_scene_ir_json;
using toporoom::adapters::scene_ir_to_json;
using toporoom::adapters::validate_scene_ir_json;
using toporoom::domain::AddWallProps;
using toporoom::domain::CloseRoomProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FaceDatum;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::HostedKind;
using toporoom::domain::LengthMm;
using toporoom::domain::OpeningKind;
using toporoom::domain::PlaceHostedComponentProps;
using toporoom::domain::PointMm;
using toporoom::domain::SpaceType;
using toporoom::domain::WallKind;
using toporoom::domain::opening_kind_from_string;

namespace {

void add_rect(FloorPlanDocument& doc, const std::string& storey_id) {
  const struct {
    const char* id;
    double x0, y0, x1, y1;
    double height;
  } walls[] = {
      {"wall_n", 0, 3000, 4000, 3000, 2800},
      {"wall_e", 4000, 3000, 4000, 0, 2800},
      {"wall_s", 4000, 0, 0, 0, 2800},
      {"wall_w", 0, 0, 0, 3000, 2400},
  };
  for (const auto& wall : walls) {
    AddWallProps props;
    props.storey_id = storey_id;
    props.id = wall.id;
    props.start = PointMm::of(wall.x0, wall.y0);
    props.end = PointMm::of(wall.x1, wall.y1);
    props.thickness = LengthMm::of(200);
    props.height = LengthMm::of(wall.height);
    props.kind = WallKind::Exterior;
    doc.add_wall(props);
  }
}

}  // namespace

TEST(DomainModelV02, OpeningKindRequiresDoorWindowOrArchway) {
  EXPECT_EQ(opening_kind_from_string("door"), OpeningKind::Door);
  EXPECT_EQ(opening_kind_from_string("window"), OpeningKind::Window);
  EXPECT_EQ(opening_kind_from_string("archway"), OpeningKind::Archway);
  EXPECT_FALSE(opening_kind_from_string("passage").has_value());
  EXPECT_FALSE(opening_kind_from_string("").has_value());
}

TEST(DomainModelV02, StoreyHeightIsNotClearHeight) {
  CreateFloorPlanProps props{"doc_heights"};
  props.face_datum = FaceDatum::Structural;
  auto doc = FloorPlanDocument::create(props);
  const auto storey_id = doc.storeys()[0].id();
  EXPECT_EQ(doc.storeys()[0].height().value(), 2800);
  add_rect(doc, storey_id);
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_living";
  room.name = "客厅";
  room.space_type = SpaceType::Interior;
  room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
  room.clear_height = LengthMm::of(2650);
  doc.close_room(room);
  EXPECT_EQ(doc.storeys()[0].height().value(), 2800);
  ASSERT_TRUE(doc.storeys()[0].rooms()[0].clear_height().has_value());
  EXPECT_EQ(doc.storeys()[0].rooms()[0].clear_height()->value(), 2650);
  EXPECT_NE(doc.storeys()[0].height().value(),
            doc.storeys()[0].rooms()[0].clear_height()->value());
}

TEST(DomainModelV02, StoreyHeightChangeFollowsMatchingWallsAndKeepsOverrides) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_follow"});
  const auto storey_id = doc.storeys()[0].id();
  add_rect(doc, storey_id);
  doc.set_storey_height(storey_id, LengthMm::of(3000), true);
  EXPECT_EQ(doc.storeys()[0].height().value(), 3000);
  EXPECT_EQ(doc.storeys()[0].wall_by_id("wall_n").height().value(), 3000);
  EXPECT_EQ(doc.storeys()[0].wall_by_id("wall_w").height().value(), 2400);
}

TEST(DomainModelV02, HostedComponentDoesNotBlockP0) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_hc"});
  EXPECT_TRUE(doc.storeys()[0].hosted_components().empty());
  PlaceHostedComponentProps hc;
  hc.storey_id = doc.storeys()[0].id();
  hc.id = "hc_beam_1";
  hc.kind = HostedKind::Beam;
  hc.z_bottom_mm = 2400;
  hc.depth_mm = 400;
  doc.place_hosted_component(hc);
  ASSERT_EQ(doc.storeys()[0].hosted_components().size(), 1u);
  EXPECT_EQ(doc.storeys()[0].hosted_components()[0].kind, HostedKind::Beam);
}

TEST(DomainModelV02, LoadsLegacySceneIr01AndWrites02) {
  const auto v01 = load_scene_ir_file(std::string(TOPOROOM_FIXTURE_DIR) +
                                      "/rect-room-door-laser.sceneir.json");
  EXPECT_EQ(v01.version, "0.1");
  EXPECT_EQ(v01.storeys[0].walls[2].openings[0].kind, OpeningKind::Door);
  const auto doc = FloorPlanDocument::from_scene_ir(v01);
  EXPECT_EQ(doc.to_scene_ir().version, "0.2");
}

TEST(DomainModelV02, LoadsAdditiveSceneIr02WithKindNotType) {
  const auto path = std::string(TOPOROOM_FIXTURE_DIR) +
                    "/rect-room-v02-archway-clearheight.sceneir.json";
  const auto scene = load_scene_ir_file(path);
  EXPECT_EQ(scene.version, "0.2");
  EXPECT_EQ(scene.meta.face_datum, FaceDatum::Structural);
  EXPECT_EQ(scene.storeys[0].rooms[0].clear_height_mm, std::optional<double>{2650});
  EXPECT_EQ(scene.storeys[0].walls[1].openings[0].kind, OpeningKind::Archway);
  EXPECT_EQ(scene.storeys[0].hosted_components[0].kind, HostedKind::Beam);
  EXPECT_EQ(scene.measurements[0].target->entity_type, "openingWidth");
  const auto json = scene_ir_to_json(FloorPlanDocument::from_scene_ir(scene).to_scene_ir());
  EXPECT_NE(json.find("\"kind\": \"archway\""), std::string::npos);
  EXPECT_EQ(json.find("\"type\": \"archway\""), std::string::npos);
}

TEST(DomainModelV02, OpeningTypeAliasStillLoads) {
  const char* snippet = R"({
    "format": "toporoom.sceneir",
    "version": "0.2",
    "id": "alias",
    "units": "mm",
    "storeys": [{
      "id": "storey_1",
      "elevationMm": 0,
      "heightMm": 2800,
      "walls": [{
        "id": "wall_s",
        "kind": "exterior",
        "start": {"x": 0, "y": 0},
        "end": {"x": 4000, "y": 0},
        "thicknessMm": 200,
        "heightMm": 2800,
        "openings": [{
          "id": "op_a",
          "type": "archway",
          "widthMm": 1200,
          "heightMm": 2100,
          "offsetMm": 100,
          "sillHeightMm": 0
        }]
      }],
      "rooms": []
    }],
    "measurements": []
  })";
  EXPECT_TRUE(validate_scene_ir_json(snippet).empty());
  const auto scene = load_scene_ir_json(snippet);
  EXPECT_EQ(scene.storeys[0].walls[0].openings[0].kind, OpeningKind::Archway);
}
