#include <string>
#include <variant>

#include <gtest/gtest.h>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/events.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

using toporoom::domain::AddOpeningProps;
using toporoom::domain::AddWallProps;
using toporoom::domain::CloseRoomProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::DomainError;
using toporoom::domain::event_type;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::LengthMm;
using toporoom::domain::OpeningAdded;
using toporoom::domain::OpeningKind;
using toporoom::domain::PointMm;
using toporoom::domain::RoomClosed;
using toporoom::domain::WallAdded;
using toporoom::domain::WallKind;

namespace {

AddWallProps rect_wall(const char* id, double x0, double y0, double x1, double y1) {
  AddWallProps props;
  props.id = id;
  props.start = PointMm::of(x0, y0);
  props.end = PointMm::of(x1, y1);
  props.thickness = LengthMm::of(200);
  props.height = LengthMm::of(2800);
  props.kind = WallKind::Exterior;
  return props;
}

}  // namespace

TEST(FloorPlanDocument, CreatesSceneIr01InMillimetres) {
  const auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  EXPECT_STREQ(doc.format().c_str(), "toporoom.sceneir");
  EXPECT_STREQ(doc.version().c_str(), "0.1");
  EXPECT_STREQ(doc.units().c_str(), "mm");
  EXPECT_EQ(doc.storeys().size(), 1u);
}

TEST(FloorPlanDocument, EmitsWallAdded) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  const std::string storey_id = doc.storeys()[0].id();
  auto props = rect_wall("wall_s", 0, 0, 4000, 0);
  props.storey_id = storey_id;
  doc.add_wall(props);
  const auto events = doc.pull_domain_events();
  ASSERT_EQ(events.size(), 2u);
  EXPECT_STREQ(event_type(events[0]), "WallAdded");
  EXPECT_STREQ(event_type(events[1]), "FloorPlanSemanticsChanged");
  const auto added = std::get<WallAdded>(events[0]);
  EXPECT_EQ(added.wall_id, "wall_s");
  EXPECT_EQ(added.storey_id, storey_id);
}

TEST(FloorPlanDocument, EmitsOpeningAdded) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  const std::string storey_id = doc.storeys()[0].id();
  auto wall = rect_wall("wall_s", 0, 0, 4000, 0);
  wall.storey_id = storey_id;
  doc.add_wall(wall);
  doc.pull_domain_events();
  AddOpeningProps opening;
  opening.storey_id = storey_id;
  opening.wall_id = "wall_s";
  opening.id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width = LengthMm::of(900);
  opening.height = LengthMm::of(2100);
  opening.offset_along_wall = LengthMm::of(800);
  opening.sill_height = LengthMm::of(0);
  doc.add_opening(opening);
  const auto events = doc.pull_domain_events();
  ASSERT_GE(events.size(), 1u);
  EXPECT_STREQ(event_type(events[0]), "OpeningAdded");
  EXPECT_EQ(std::get<OpeningAdded>(events[0]).opening_id, "op_door");
}

TEST(FloorPlanDocument, EmitsRoomClosed) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  const std::string storey_id = doc.storeys()[0].id();
  auto n = rect_wall("wall_n", 0, 3000, 4000, 3000);
  auto e = rect_wall("wall_e", 4000, 3000, 4000, 0);
  auto s = rect_wall("wall_s", 4000, 0, 0, 0);
  auto w = rect_wall("wall_w", 0, 0, 0, 3000);
  n.storey_id = e.storey_id = s.storey_id = w.storey_id = storey_id;
  doc.add_wall(n);
  doc.add_wall(e);
  doc.add_wall(s);
  doc.add_wall(w);
  doc.pull_domain_events();
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_living";
  room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
  doc.close_room(room);
  const auto events = doc.pull_domain_events();
  EXPECT_STREQ(event_type(events[0]), "RoomClosed");
  EXPECT_EQ(std::get<RoomClosed>(events[0]).room_id, "room_living");
}

TEST(FloorPlanDocument, RejectsUnclosedRoom) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  const std::string storey_id = doc.storeys()[0].id();
  auto n = rect_wall("wall_n", 0, 3000, 4000, 3000);
  auto e = rect_wall("wall_e", 4000, 3000, 4000, 0);
  n.storey_id = e.storey_id = storey_id;
  doc.add_wall(n);
  doc.add_wall(e);
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_open";
  room.wall_ids = {"wall_n", "wall_e"};
  EXPECT_THROW(doc.close_room(room), DomainError);
}

TEST(FloorPlanDocument, RoundTripsSceneIr) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  const std::string storey_id = doc.storeys()[0].id();
  auto n = rect_wall("wall_n", 0, 3000, 4000, 3000);
  auto e = rect_wall("wall_e", 4000, 3000, 4000, 0);
  auto s = rect_wall("wall_s", 4000, 0, 0, 0);
  auto w = rect_wall("wall_w", 0, 0, 0, 3000);
  n.storey_id = e.storey_id = s.storey_id = w.storey_id = storey_id;
  doc.add_wall(n);
  doc.add_wall(e);
  doc.add_wall(s);
  doc.add_wall(w);
  AddOpeningProps opening;
  opening.storey_id = storey_id;
  opening.wall_id = "wall_s";
  opening.id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width = LengthMm::of(900);
  opening.height = LengthMm::of(2100);
  opening.offset_along_wall = LengthMm::of(800);
  doc.add_opening(opening);
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_living";
  room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
  doc.close_room(room);
  const auto snapshot = doc.to_scene_ir();
  const auto restored = FloorPlanDocument::from_scene_ir(snapshot);
  EXPECT_EQ(restored.to_scene_ir().id, snapshot.id);
  EXPECT_EQ(restored.to_scene_ir().storeys[0].walls.size(), 4u);
  EXPECT_EQ(snapshot.format, "toporoom.sceneir");
  EXPECT_EQ(snapshot.version, "0.1");
  EXPECT_EQ(snapshot.units, "mm");
}
