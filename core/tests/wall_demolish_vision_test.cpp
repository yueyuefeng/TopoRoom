#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/floor_plan_vision_adapters.hpp"
#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/adapters/in_memory_document_store.hpp"
#include "toporoom/app/floor_plan_edit_service.hpp"
#include "toporoom/app/rebuild_policy.hpp"
#include "toporoom/c_api/toporoom.h"
#include "toporoom/domain/error.hpp"
#include "toporoom/domain/events.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"

using toporoom::adapters::FakeGeometryPort;
using toporoom::adapters::FakeVisionAdapter;
using toporoom::adapters::InMemoryDocumentStore;
using toporoom::adapters::OnDeviceMlVisionAdapter;
using toporoom::app::DemolishWallCommand;
using toporoom::app::FloorPlanEditService;
using toporoom::app::SessionIsolate;
using toporoom::domain::AddOpeningProps;
using toporoom::domain::AddWallProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::DomainError;
using toporoom::domain::event_type;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::LengthMm;
using toporoom::domain::OpeningKind;
using toporoom::domain::PointMm;
using toporoom::domain::WallKind;
using toporoom::ports::VisionRequest;

namespace {

FloorPlanDocument rect_with_kinds() {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_demo"});
  const std::string storey = doc.storeys()[0].id();
  auto add = [&](const char* id, double x0, double y0, double x1, double y1, WallKind kind,
                 double thickness = 200) {
    AddWallProps p;
    p.storey_id = storey;
    p.id = id;
    p.start = PointMm::of(x0, y0);
    p.end = PointMm::of(x1, y1);
    p.thickness = LengthMm::of(thickness);
    p.height = LengthMm::of(2800);
    p.kind = kind;
    doc.add_wall(std::move(p));
  };
  add("wall_n", 0, 3000, 4000, 3000, WallKind::ShearWall);
  add("wall_s", 4000, 0, 0, 0, WallKind::ShearWall);
  add("wall_p", 2000, 0, 2000, 3000, WallKind::Masonry, 120);
  return doc;
}

}  // namespace

TEST(FloorPlanVision, FakeIsDeterministicWithKinds) {
  FakeVisionAdapter fake;
  VisionRequest a_req;
  a_req.image_uri = "fixture:photo";
  VisionRequest b_req;
  b_req.image_uri = "/tmp/any.jpg";
  const auto a = fake.detect_walls(a_req);
  const auto b = fake.detect_walls(b_req);
  ASSERT_TRUE(a.ok);
  ASSERT_TRUE(b.ok);
  ASSERT_EQ(a.walls.size(), 5u);
  EXPECT_EQ(a.walls.size(), b.walls.size());
  int shear = 0;
  int masonry = 0;
  for (const auto& w : a.walls) {
    if (w.kind == WallKind::ShearWall) ++shear;
    if (w.kind == WallKind::Masonry) ++masonry;
  }
  EXPECT_EQ(shear, 4);
  EXPECT_EQ(masonry, 1);
  EXPECT_EQ(a.walls[4].id, "wall_p");
}

TEST(FloorPlanVision, OnDeviceMlIsStub) {
  OnDeviceMlVisionAdapter ml;
  VisionRequest req;
  req.image_uri = "camera://0";
  const auto r = ml.detect_walls(req);
  EXPECT_FALSE(r.ok);
  EXPECT_NE(r.error.find("not linked"), std::string::npos);
  EXPECT_EQ(toporoom_vision_ml_available(), 0);
}

TEST(WallDemolish, MasonryPartitionCanBeRemoved) {
  auto doc = rect_with_kinds();
  const std::string storey = doc.storeys()[0].id();
  doc.demolish_wall(storey, "wall_p", false);
  EXPECT_FALSE(doc.storeys()[0].has_wall("wall_p"));
  EXPECT_TRUE(doc.storeys()[0].has_wall("wall_n"));
}

TEST(WallDemolish, ShearRequiresForceFlag) {
  auto doc = rect_with_kinds();
  const std::string storey = doc.storeys()[0].id();
  try {
    doc.demolish_wall(storey, "wall_n", false);
    FAIL() << "expected DomainError";
  } catch (const DomainError& err) {
    EXPECT_EQ(err.code(), "SHEAR_WALL_PROTECTED");
    EXPECT_NE(std::string(err.what()).find("force"), std::string::npos);
  }
  EXPECT_TRUE(doc.storeys()[0].has_wall("wall_n"));
  doc.demolish_wall(storey, "wall_n", true);
  EXPECT_FALSE(doc.storeys()[0].has_wall("wall_n"));
}

TEST(WallDemolish, ToggleKindThenDemolish) {
  auto doc = rect_with_kinds();
  const std::string storey = doc.storeys()[0].id();
  doc.set_wall_kind(storey, "wall_n", WallKind::Masonry);
  EXPECT_EQ(doc.storeys()[0].wall_by_id("wall_n").kind(), WallKind::Masonry);
  doc.demolish_wall(storey, "wall_n", false);
  EXPECT_FALSE(doc.storeys()[0].has_wall("wall_n"));
}

TEST(WallDemolish, SplitAndPartialMasonry) {
  auto doc = rect_with_kinds();
  const std::string storey = doc.storeys()[0].id();
  const std::string second = doc.split_wall(storey, "wall_p", LengthMm::of(1500));
  EXPECT_TRUE(doc.storeys()[0].has_wall("wall_p"));
  EXPECT_TRUE(doc.storeys()[0].has_wall(second));
  EXPECT_NEAR(doc.storeys()[0].wall_by_id("wall_p").length_mm().value(), 1500, 1e-3);
  doc.partial_demolish(storey, second, LengthMm::of(200), LengthMm::of(400), false);
  EXPECT_GT(doc.storeys()[0].walls().size(), 3u);
}

TEST(WallDemolish, SplitKeepsOpeningsOnEachSide) {
  auto doc = rect_with_kinds();
  const std::string storey = doc.storeys()[0].id();
  AddOpeningProps first_op;
  first_op.storey_id = storey;
  first_op.wall_id = "wall_p";
  first_op.id = "op_a";
  first_op.kind = OpeningKind::Door;
  first_op.width = LengthMm::of(900);
  first_op.height = LengthMm::of(2100);
  first_op.offset_along_wall = LengthMm::of(200);
  doc.add_opening(first_op);
  AddOpeningProps second_op = first_op;
  second_op.id = "op_b";
  second_op.offset_along_wall = LengthMm::of(1800);
  doc.add_opening(std::move(second_op));
  const std::string second = doc.split_wall(storey, "wall_p", LengthMm::of(1500));
  EXPECT_EQ(doc.storeys()[0].wall_by_id("wall_p").openings().size(), 1u);
  EXPECT_EQ(doc.storeys()[0].wall_by_id(second).openings().size(), 1u);
  EXPECT_EQ(doc.storeys()[0].wall_by_id("wall_p").openings()[0].id(), "op_a");
  EXPECT_EQ(doc.storeys()[0].wall_by_id(second).openings()[0].id(), "op_b");
}

TEST(WallDemolish, PartialShearNeedsForce) {
  auto doc = rect_with_kinds();
  const std::string storey = doc.storeys()[0].id();
  EXPECT_THROW(doc.partial_demolish(storey, "wall_s", LengthMm::of(800), LengthMm::of(900),
                                    false),
               DomainError);
  doc.partial_demolish(storey, "wall_s", LengthMm::of(800), LengthMm::of(900), true);
  EXPECT_TRUE(doc.storeys()[0].has_wall("wall_s"));
}

TEST(WallDemolish, EditServiceAndCApi) {
  InMemoryDocumentStore store;
  FakeGeometryPort geometry;
  toporoom::app::GeometryRebuildPolicy rebuild(geometry);
  SessionIsolate isolate;
  FloorPlanEditService edits(store, rebuild, isolate);
  auto created = FloorPlanDocument::create(CreateFloorPlanProps{"doc_api"});
  const std::string storey = created.storeys()[0].id();
  store.save(created.to_scene_ir());

  AddWallProps p;
  p.storey_id = storey;
  p.id = "wall_p";
  p.start = PointMm::of(0, 0);
  p.end = PointMm::of(0, 3000);
  p.thickness = LengthMm::of(120);
  p.height = LengthMm::of(2800);
  p.kind = WallKind::Masonry;
  created.add_wall(p);
  p.id = "wall_n";
  p.start = PointMm::of(0, 3000);
  p.end = PointMm::of(4000, 3000);
  p.thickness = LengthMm::of(200);
  p.kind = WallKind::ShearWall;
  created.add_wall(std::move(p));
  store.save(created.to_scene_ir());

  DemolishWallCommand blocked;
  blocked.document_id = "doc_api";
  blocked.storey_id = storey;
  blocked.wall_id = "wall_n";
  blocked.force = false;
  EXPECT_THROW(edits.demolish_wall(blocked), DomainError);

  DemolishWallCommand ok;
  ok.document_id = "doc_api";
  ok.storey_id = storey;
  ok.wall_id = "wall_p";
  ok.force = false;
  const auto gone = edits.demolish_wall(ok);
  bool saw_removed = false;
  for (const auto& event : gone.events) {
    if (std::string(event_type(event)) == "WallRemoved") saw_removed = true;
  }
  EXPECT_TRUE(saw_removed);

  TopoRoomDocument* doc = toporoom_document_create("doc_c_demo");
  ASSERT_NE(doc, nullptr);
  char err[256] = {};
  ASSERT_EQ(toporoom_document_import_fake_vision(doc, "fixture:photo", err, sizeof(err)), 0)
      << err;
  char sid[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, sid, sizeof(sid)), 0);
  EXPECT_NE(toporoom_document_demolish_wall(doc, sid, "wall_n", 0, err, sizeof(err)), 0);
  EXPECT_NE(std::string(err).find("force"), std::string::npos);
  ASSERT_EQ(toporoom_document_demolish_wall(doc, sid, "wall_p", 0, err, sizeof(err)), 0)
      << err;
  ASSERT_EQ(toporoom_document_set_wall_kind(doc, sid, "wall_e", "masonry", err, sizeof(err)),
            0)
      << err;
  char nid[64] = {};
  ASSERT_EQ(toporoom_document_split_wall(doc, sid, "wall_s", 2000, nid, sizeof(nid), err,
                                         sizeof(err)),
            0)
      << err;
  EXPECT_NE(std::string(nid).find("wall"), std::string::npos);
  toporoom_document_destroy(doc);
}

TEST(FloorPlanVision, ImportFakeVisionWritesSceneIrKinds) {
  TopoRoomDocument* doc = toporoom_document_create("doc_photo");
  ASSERT_NE(doc, nullptr);
  char err[256] = {};
  ASSERT_EQ(toporoom_document_import_fake_vision(doc, nullptr, err, sizeof(err)), 0) << err;
  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  const std::string text(json);
  EXPECT_NE(text.find("shearWall"), std::string::npos);
  EXPECT_NE(text.find("masonry"), std::string::npos);
  EXPECT_NE(text.find("wall_p"), std::string::npos);
  toporoom_string_free(json);
  toporoom_document_destroy(doc);
}
