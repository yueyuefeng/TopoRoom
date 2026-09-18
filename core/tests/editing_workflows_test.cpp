#include <algorithm>
#include <stdexcept>
#include <string>
#include <variant>

#include <gtest/gtest.h>

#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/adapters/in_memory_document_store.hpp"
#include "toporoom/app/editing_tools.hpp"
#include "toporoom/app/export_app_service.hpp"
#include "toporoom/app/floor_plan_edit_service.hpp"
#include "toporoom/app/guided_edit_workflow.hpp"
#include "toporoom/c_api/toporoom.h"
#include "toporoom/domain/error.hpp"
#include "toporoom/domain/events.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::adapters::FakeGeometryPort;
using toporoom::adapters::InMemoryDocumentStore;
using toporoom::app::AddOpeningCommand;
using toporoom::app::AddWallCommand;
using toporoom::app::CloseRoomCommand;
using toporoom::app::DeleteHostedComponentCommand;
using toporoom::app::DeleteOpeningCommand;
using toporoom::app::DeleteWallCommand;
using toporoom::app::FloorPlanEditService;
using toporoom::app::GuidedEditWorkflow;
using toporoom::app::GuidePhase;
using toporoom::app::MoveWallCommand;
using toporoom::app::PlaceHostedComponentCommand;
using toporoom::app::PlaceHostedComponentTool;
using toporoom::app::PlaceOpeningTool;
using toporoom::app::register_p0_editing_tools;
using toporoom::app::ResizeWallCommand;
using toporoom::app::SessionIsolate;
using toporoom::app::SetClearHeightTool;
using toporoom::app::SetMeasurementCommand;
using toporoom::app::SetRoomAttributesCommand;
using toporoom::app::SetStoreyHeightCommand;
using toporoom::app::SetStoreyHeightTool;
using toporoom::app::SetWallHeightCommand;
using toporoom::app::SetWallThicknessCommand;
using toporoom::app::ToolRegistry;
using toporoom::app::UpdateHostedComponentCommand;
using toporoom::app::UpdateOpeningCommand;
using toporoom::app::WallDrawTool;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::event_type;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::HostedKind;
using toporoom::domain::MeasurementSource;
using toporoom::domain::OpeningKind;
using toporoom::domain::SpaceType;
using toporoom::domain::WallKind;
using toporoom::ports::FaultCode;

namespace {

struct Harness {
  InMemoryDocumentStore store;
  FakeGeometryPort geometry;
  toporoom::app::GeometryRebuildPolicy rebuild;
  SessionIsolate isolate;
  FloorPlanEditService edits;
  std::string storey_id;

  Harness()
      : rebuild(geometry), edits(store, rebuild, isolate) {
    auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_edit"});
    storey_id = doc.storeys()[0].id();
    store.save(doc.to_scene_ir());
  }

  AddWallCommand wall(const char* id, double x0, double y0, double x1, double y1,
                      double height = 2800) const {
    AddWallCommand cmd;
    cmd.document_id = "doc_edit";
    cmd.storey_id = storey_id;
    cmd.wall_id = id;
    cmd.start_x = x0;
    cmd.start_y = y0;
    cmd.end_x = x1;
    cmd.end_y = y1;
    cmd.thickness_mm = 200;
    cmd.height_mm = height;
    cmd.kind = WallKind::Exterior;
    return cmd;
  }

  void add_rect() {
    edits.add_wall(wall("wall_n", 0, 3000, 4000, 3000));
    edits.add_wall(wall("wall_e", 4000, 3000, 4000, 0));
    edits.add_wall(wall("wall_s", 4000, 0, 0, 0));
    edits.add_wall(wall("wall_w", 0, 0, 0, 3000));
  }
};

bool has_event(const std::vector<toporoom::domain::DomainEvent>& events, const char* type) {
  return std::any_of(events.begin(), events.end(), [&](const auto& event) {
    return std::string(event_type(event)) == type;
  });
}

}  // namespace

TEST(EditingWorkflows, WallAddMoveResizeDelete) {
  Harness h;
  auto added = h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));
  EXPECT_TRUE(has_event(added.events, "WallAdded"));
  EXPECT_TRUE(added.rebuild.ok);

  MoveWallCommand move;
  move.document_id = "doc_edit";
  move.storey_id = h.storey_id;
  move.wall_id = "wall_s";
  move.end_x = 4500;
  auto moved = h.edits.move_wall(move);
  EXPECT_TRUE(has_event(moved.events, "WallGeometryChanged"));
  EXPECT_EQ(moved.scene.storeys[0].walls[0].end.x, 4500);

  ResizeWallCommand resize;
  resize.document_id = "doc_edit";
  resize.storey_id = h.storey_id;
  resize.wall_id = "wall_s";
  resize.length_mm = 3000;
  auto resized = h.edits.resize_wall(resize);
  EXPECT_NEAR(resized.scene.storeys[0].walls[0].end.x, 3000, 1e-6);

  DeleteWallCommand del;
  del.document_id = "doc_edit";
  del.storey_id = h.storey_id;
  del.wall_id = "wall_s";
  auto removed = h.edits.delete_wall(del);
  EXPECT_TRUE(has_event(removed.events, "WallRemoved"));
  EXPECT_TRUE(removed.scene.storeys[0].walls.empty());

  auto again = h.edits.delete_wall(del);
  EXPECT_TRUE(again.scene.storeys[0].walls.empty());
}

TEST(EditingWorkflows, OpeningKindRequiredArchwayAndCrud) {
  Harness h;
  h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));

  PlaceOpeningTool tool;
  auto fsm = tool.create_fsm();
  fsm.provide("wall_id", "wall_s");
  EXPECT_THROW(fsm.provide("kind", "bare"), std::runtime_error);
  auto ok = tool.create_fsm();
  ok.provide("wall_id", "wall_s");
  ok.provide("kind", "archway");
  ok.provide("offset", "800");
  ok.provide("width", "1200");
  ok.provide("height", "2100");
  ok.provide("sill", "0");
  const auto draft = PlaceOpeningTool::complete(ok.params());
  EXPECT_EQ(draft.kind, OpeningKind::Archway);

  AddOpeningCommand add;
  add.document_id = "doc_edit";
  add.storey_id = h.storey_id;
  add.wall_id = "wall_s";
  add.opening_id = "op_arch";
  add.kind = OpeningKind::Archway;
  add.width_mm = 1200;
  add.height_mm = 2100;
  add.offset_mm = 800;
  auto placed = h.edits.add_opening(add);
  EXPECT_TRUE(has_event(placed.events, "OpeningAdded"));
  EXPECT_EQ(placed.scene.storeys[0].walls[0].openings[0].kind, OpeningKind::Archway);

  UpdateOpeningCommand upd;
  upd.document_id = "doc_edit";
  upd.storey_id = h.storey_id;
  upd.opening_id = "op_arch";
  upd.kind = OpeningKind::Window;
  upd.width_mm = 1500;
  upd.height_mm = 1400;
  upd.offset_mm = 500;
  upd.sill_height_mm = 900;
  auto updated = h.edits.update_opening(upd);
  EXPECT_TRUE(has_event(updated.events, "OpeningChanged"));
  EXPECT_EQ(updated.scene.storeys[0].walls[0].openings[0].kind, OpeningKind::Window);
  EXPECT_EQ(updated.scene.storeys[0].walls[0].openings[0].width_mm, 1500);

  DeleteOpeningCommand del;
  del.document_id = "doc_edit";
  del.storey_id = h.storey_id;
  del.opening_id = "op_arch";
  auto gone = h.edits.delete_opening(del);
  EXPECT_TRUE(has_event(gone.events, "OpeningRemoved"));
  EXPECT_TRUE(gone.scene.storeys[0].walls[0].openings.empty());
}

TEST(EditingWorkflows, FlipOpeningMirrorsOffsetAlongWall) {
  Harness h;
  h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));
  AddOpeningCommand add;
  add.document_id = "doc_edit";
  add.storey_id = h.storey_id;
  add.wall_id = "wall_s";
  add.opening_id = "op_door";
  add.kind = OpeningKind::Door;
  add.width_mm = 900;
  add.height_mm = 2100;
  add.offset_mm = 800;
  h.edits.add_opening(add);

  const double wall_len = 4000;
  const double width = 900;
  const double offset = 800;
  const double flipped = wall_len - offset - width;
  EXPECT_NEAR(flipped, 2300, 1e-6);

  UpdateOpeningCommand upd;
  upd.document_id = "doc_edit";
  upd.storey_id = h.storey_id;
  upd.opening_id = "op_door";
  upd.kind = OpeningKind::Door;
  upd.width_mm = width;
  upd.height_mm = 2100;
  upd.offset_mm = flipped;
  auto result = h.edits.update_opening(upd);
  EXPECT_TRUE(has_event(result.events, "OpeningChanged"));
  EXPECT_NEAR(result.scene.storeys[0].walls[0].openings[0].offset_mm, 2300, 1e-6);
}

TEST(EditingWorkflows, DuplicateOpeningPlacesSiblingOnSameWall) {
  Harness h;
  h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));
  AddOpeningCommand add;
  add.document_id = "doc_edit";
  add.storey_id = h.storey_id;
  add.wall_id = "wall_s";
  add.opening_id = "op_src";
  add.kind = OpeningKind::Window;
  add.width_mm = 900;
  add.height_mm = 1400;
  add.offset_mm = 800;
  add.sill_height_mm = 900;
  h.edits.add_opening(add);

  const double gap = 200;
  const double sibling = 800 + 900 + gap;
  AddOpeningCommand dup;
  dup.document_id = "doc_edit";
  dup.storey_id = h.storey_id;
  dup.wall_id = "wall_s";
  dup.opening_id = "op_dup";
  dup.kind = OpeningKind::Window;
  dup.width_mm = 900;
  dup.height_mm = 1400;
  dup.offset_mm = sibling;
  dup.sill_height_mm = 900;
  auto result = h.edits.add_opening(dup);
  EXPECT_TRUE(has_event(result.events, "OpeningAdded"));
  ASSERT_EQ(result.scene.storeys[0].walls[0].openings.size(), 2u);
  EXPECT_NEAR(result.scene.storeys[0].walls[0].openings[1].offset_mm, 1900, 1e-6);
}

TEST(EditingWorkflows, SetWallThicknessWritesSceneIR) {
  Harness h;
  h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));
  SetWallThicknessCommand thick;
  thick.document_id = "doc_edit";
  thick.storey_id = h.storey_id;
  thick.wall_id = "wall_s";
  thick.thickness_mm = 120;
  auto result = h.edits.set_wall_thickness(thick);
  EXPECT_TRUE(has_event(result.events, "WallGeometryChanged"));
  EXPECT_NEAR(result.scene.storeys[0].walls[0].thickness_mm, 120, 1e-6);
  EXPECT_NEAR(result.scene.storeys[0].walls[0].end.x, 4000, 1e-6);
}

TEST(EditingWorkflows, RoomAttributesClearHeightIsNotStoreyHeight) {
  Harness h;
  h.add_rect();
  CloseRoomCommand room;
  room.document_id = "doc_edit";
  room.storey_id = h.storey_id;
  room.room_id = "room_living";
  room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
  room.name = "客厅";
  room.space_type = SpaceType::Interior;
  h.edits.close_room(room);

  SetRoomAttributesCommand attrs;
  attrs.document_id = "doc_edit";
  attrs.storey_id = h.storey_id;
  attrs.room_id = "room_living";
  attrs.name = "阳台";
  attrs.space_type = SpaceType::Balcony;
  attrs.clear_height_mm = 2650;
  auto result = h.edits.set_room_attributes(attrs);
  EXPECT_TRUE(has_event(result.events, "RoomAttributesChanged"));
  EXPECT_EQ(result.scene.storeys[0].rooms[0].name, "阳台");
  EXPECT_EQ(result.scene.storeys[0].rooms[0].space_type, SpaceType::Balcony);
  ASSERT_TRUE(result.scene.storeys[0].rooms[0].clear_height_mm);
  EXPECT_EQ(*result.scene.storeys[0].rooms[0].clear_height_mm, 2650);
  EXPECT_EQ(result.scene.storeys[0].height_mm, 2800);
}

TEST(EditingWorkflows, StoreyHeightFollowsWallsAndAllowsOverride) {
  Harness h;
  h.edits.add_wall(h.wall("wall_follow", 0, 0, 4000, 0, 2800));
  h.edits.add_wall(h.wall("wall_override", 4000, 0, 4000, 3000, 2400));

  SetWallHeightCommand override_cmd;
  override_cmd.document_id = "doc_edit";
  override_cmd.storey_id = h.storey_id;
  override_cmd.wall_id = "wall_override";
  override_cmd.height_mm = 2400;
  h.edits.set_wall_height(override_cmd);

  SetStoreyHeightCommand height;
  height.document_id = "doc_edit";
  height.storey_id = h.storey_id;
  height.height_mm = 3000;
  height.follow_matching_walls = true;
  auto result = h.edits.set_storey_height(height);
  EXPECT_TRUE(has_event(result.events, "StoreyHeightChanged"));
  EXPECT_EQ(result.scene.storeys[0].height_mm, 3000);
  EXPECT_EQ(result.scene.storeys[0].walls[0].height_mm, 3000);
  EXPECT_EQ(result.scene.storeys[0].walls[1].height_mm, 2400);
}

TEST(EditingWorkflows, HostedComponentCrud) {
  Harness h;
  h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));
  PlaceHostedComponentCommand place;
  place.document_id = "doc_edit";
  place.storey_id = h.storey_id;
  place.component_id = "hc_beam";
  place.kind = HostedKind::Beam;
  place.z_bottom_mm = 2400;
  place.depth_mm = 400;
  place.host_wall_id = "wall_s";
  auto placed = h.edits.place_hosted_component(place);
  EXPECT_TRUE(has_event(placed.events, "HostedComponentPlaced"));
  EXPECT_EQ(placed.scene.storeys[0].hosted_components[0].kind, HostedKind::Beam);
  ASSERT_TRUE(placed.scene.storeys[0].hosted_components[0].host_wall_id);
  EXPECT_EQ(*placed.scene.storeys[0].hosted_components[0].host_wall_id, "wall_s");

  UpdateHostedComponentCommand upd;
  upd.document_id = "doc_edit";
  upd.storey_id = h.storey_id;
  upd.component_id = "hc_beam";
  upd.kind = HostedKind::Flue;
  upd.z_bottom_mm = 0;
  upd.depth_mm = 300;
  upd.host_wall_id = "wall_s";
  auto updated = h.edits.update_hosted_component(upd);
  EXPECT_TRUE(has_event(updated.events, "HostedComponentChanged"));
  EXPECT_EQ(updated.scene.storeys[0].hosted_components[0].kind, HostedKind::Flue);

  DeleteHostedComponentCommand del;
  del.document_id = "doc_edit";
  del.storey_id = h.storey_id;
  del.component_id = "hc_beam";
  auto gone = h.edits.delete_hosted_component(del);
  EXPECT_TRUE(has_event(gone.events, "HostedComponentRemoved"));
  EXPECT_TRUE(gone.scene.storeys[0].hosted_components.empty());
}

TEST(EditingWorkflows, SetMeasurementLaserTypedDepthFit) {
  Harness h;
  h.edits.add_wall(h.wall("wall_s", 0, 0, 4000, 0));
  SetMeasurementCommand laser;
  laser.document_id = "doc_edit";
  laser.measurement_id = "m_s";
  laser.value_mm = 4000;
  laser.source = MeasurementSource::Laser;
  laser.between = {"wall_s"};
  auto result = h.edits.set_measurement(laser);
  EXPECT_EQ(result.scene.measurements[0].source, MeasurementSource::Laser);

  SetMeasurementCommand depth;
  depth.document_id = "doc_edit";
  depth.measurement_id = "m_s";
  depth.value_mm = 3990;
  depth.source = MeasurementSource::DepthFit;
  EXPECT_THROW(h.edits.set_measurement(depth), toporoom::domain::DomainError);

  SetMeasurementCommand typed;
  typed.document_id = "doc_edit";
  typed.measurement_id = "m_typed";
  typed.value_mm = 3000;
  typed.source = MeasurementSource::Typed;
  typed.between = {"wall_s"};
  auto typed_r = h.edits.set_measurement(typed);
  EXPECT_EQ(typed_r.scene.measurements[1].source, MeasurementSource::Typed);
}

TEST(EditingWorkflows, ToolRegistryAndParamGathering) {
  ToolRegistry registry;
  register_p0_editing_tools(registry);
  EXPECT_TRUE(registry.has(WallDrawTool::kId));
  EXPECT_TRUE(registry.has(PlaceOpeningTool::kId));
  EXPECT_TRUE(registry.has(PlaceHostedComponentTool::kId));
  EXPECT_TRUE(registry.has(SetClearHeightTool::kId));
  EXPECT_TRUE(registry.has(SetStoreyHeightTool::kId));

  auto wall_fsm = WallDrawTool().create_fsm();
  wall_fsm.provide("start", "0,0");
  wall_fsm.provide("end", "4000,0");
  wall_fsm.provide("thickness", "200");
  EXPECT_TRUE(wall_fsm.complete());

  auto hc = PlaceHostedComponentTool().create_fsm();
  hc.provide("kind", "column");
  hc.provide("z_bottom", "0");
  hc.provide("depth", "300");
  hc.provide("host_wall", "wall_s");
  EXPECT_EQ(PlaceHostedComponentTool::complete(hc.params()).kind, HostedKind::Column);

  auto ch = SetClearHeightTool().create_fsm();
  ch.provide("room_id", "room_1");
  ch.provide("clear_height", "2650");
  EXPECT_EQ(SetClearHeightTool::complete(ch.params()).clear_height_mm, 2650);

  auto sh = SetStoreyHeightTool().create_fsm();
  sh.provide("height", "3000");
  sh.provide("follow", "true");
  EXPECT_TRUE(SetStoreyHeightTool::complete(sh.params()).follow_matching_walls);
}

TEST(EditingWorkflows, GuidedMultiStepEditCompletesAcceptance) {
  InMemoryDocumentStore store;
  FakeGeometryPort geometry;
  SessionIsolate isolate;
  GuidedEditWorkflow workflow(store, geometry, isolate);
  workflow.begin("doc_guide");
  EXPECT_EQ(workflow.phase(), GuidePhase::HostCheck);
  workflow.mark_host_ok(true);

  const struct {
    const char* id;
    double x0, y0, x1, y1;
  } walls[] = {
      {"wall_n", 0, 3000, 4000, 3000},
      {"wall_e", 4000, 3000, 4000, 0},
      {"wall_s", 4000, 0, 0, 0},
      {"wall_w", 0, 0, 0, 3000},
  };
  for (const auto& w : walls) {
    AddWallCommand cmd;
    cmd.wall_id = w.id;
    cmd.start_x = w.x0;
    cmd.start_y = w.y0;
    cmd.end_x = w.x1;
    cmd.end_y = w.y1;
    cmd.thickness_mm = 200;
    cmd.height_mm = 2800;
    workflow.add_wall(cmd);
  }
  EXPECT_EQ(workflow.phase(), GuidePhase::MeasureKeys);

  SetMeasurementCommand m1;
  m1.measurement_id = "m_s";
  m1.value_mm = 4000;
  m1.source = MeasurementSource::Laser;
  m1.between = {"wall_s"};
  workflow.set_key_measurement(m1, false);
  SetMeasurementCommand m2;
  m2.measurement_id = "m_e";
  m2.value_mm = 3000;
  m2.source = MeasurementSource::Laser;
  m2.between = {"wall_e"};
  workflow.set_key_measurement(m2, false);
  EXPECT_EQ(workflow.phase(), GuidePhase::PlaceOpenings);

  AddOpeningCommand opening;
  opening.wall_id = "wall_s";
  opening.opening_id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width_mm = 900;
  opening.height_mm = 2100;
  opening.offset_mm = 800;
  auto last = workflow.add_opening(opening);
  EXPECT_TRUE(has_event(last.events, "OpeningAdded"));
  EXPECT_TRUE(workflow.can_export());
  EXPECT_EQ(workflow.phase(), GuidePhase::ExportReady);

  CloseRoomCommand room;
  room.room_id = "room_1";
  room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
  room.name = "客厅";
  room.clear_height_mm = 2650;
  workflow.close_room(room);
  EXPECT_TRUE(workflow.can_export());
}

TEST(EditingWorkflows, FaultRejectsGlbStillEmitsDxf) {
  Harness h;
  h.add_rect();
  AddOpeningCommand opening;
  opening.document_id = "doc_edit";
  opening.storey_id = h.storey_id;
  opening.wall_id = "wall_s";
  opening.opening_id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width_mm = 900;
  opening.height_mm = 2100;
  opening.offset_mm = 800;
  h.edits.add_opening(opening);
  h.geometry.fail_with({FaultCode::NotClosed, "fault", {h.storey_id}});
  auto result = h.edits.add_wall(h.wall("wall_extra", 0, 3000, 1000, 3000));
  EXPECT_FALSE(result.rebuild.ok);

  FakeGeometryPort failing;
  failing.fail_with({FaultCode::NotClosed, "fault", {h.storey_id}});
  toporoom::app::ExportAppService exporter(failing);
  const auto outcome = exporter.export_scene_graph(result.scene);
  EXPECT_FALSE(outcome.ok);
  EXPECT_TRUE(outcome.glb.empty());
  EXPECT_NE(outcome.dxf.find("WALLS"), std::string::npos);
}

TEST(EditingWorkflows, CApiGuidedEditAndOpeningKind) {
  TopoRoomDocument* doc = toporoom_document_create("doc_c_edit");
  ASSERT_NE(doc, nullptr);
  TopoRoomGuide* guide = toporoom_guide_create();
  ASSERT_NE(guide, nullptr);
  char err[256] = {};
  ASSERT_EQ(toporoom_document_run_guided_edit(doc, guide, err, sizeof(err)), 0) << err;
  EXPECT_EQ(toporoom_guide_can_export(guide), 1);
  EXPECT_STREQ(toporoom_guide_phase(guide), "export");
  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  EXPECT_NE(std::string(json).find("archway"), std::string::npos);
  EXPECT_NE(std::string(json).find("clearHeightMm"), std::string::npos);
  toporoom_string_free(json);

  char storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, storey, sizeof(storey)), 0);
  EXPECT_EQ(toporoom_document_add_opening(doc, storey, "wall_s", "op_bad", "bare", 900,
                                          2100, 200, 0, err, sizeof(err)),
            2);
  toporoom_guide_destroy(guide);
  toporoom_document_destroy(doc);
}
