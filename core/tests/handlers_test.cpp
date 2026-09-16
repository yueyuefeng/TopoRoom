#include <gtest/gtest.h>

#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/adapters/in_memory_document_store.hpp"
#include "toporoom/app/add_opening_handler.hpp"
#include "toporoom/app/add_wall_handler.hpp"
#include "toporoom/app/document_io.hpp"
#include "toporoom/app/set_measurement_handler.hpp"
#include "toporoom/domain/events.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::adapters::FakeGeometryPort;
using toporoom::adapters::InMemoryDocumentStore;
using toporoom::app::AddOpeningCommand;
using toporoom::app::AddOpeningHandler;
using toporoom::app::AddWallCommand;
using toporoom::app::AddWallHandler;
using toporoom::app::GeometryRebuildPolicy;
using toporoom::app::SetMeasurementCommand;
using toporoom::app::SetMeasurementHandler;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::event_type;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::MeasurementSource;
using toporoom::domain::OpeningKind;
using toporoom::domain::WallKind;
using toporoom::ports::FaultCode;

namespace {

struct Ctx {
  InMemoryDocumentStore store;
  FakeGeometryPort geometry;
  GeometryRebuildPolicy rebuild;
  AddWallHandler add_wall;
  AddOpeningHandler add_opening;
  SetMeasurementHandler set_measurement;
  std::string storey_id;

  Ctx()
      : rebuild(geometry),
        add_wall(store, rebuild),
        add_opening(store, rebuild),
        set_measurement(store, rebuild) {
    auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
    storey_id = doc.storeys()[0].id();
    store.save(doc.to_scene_ir());
  }
};

AddWallCommand south_wall(const std::string& storey_id) {
  AddWallCommand cmd;
  cmd.document_id = "doc_1";
  cmd.storey_id = storey_id;
  cmd.wall_id = "wall_s";
  cmd.end_x = 4000;
  cmd.thickness_mm = 200;
  cmd.height_mm = 2800;
  cmd.kind = WallKind::Exterior;
  return cmd;
}

}  // namespace

TEST(Handlers, AddWallMutatesAndRebuilds) {
  Ctx ctx;
  const auto result = ctx.add_wall.execute(south_wall(ctx.storey_id));
  bool saw_wall = false;
  for (const auto& event : result.events) {
    if (std::string(event_type(event)) == "WallAdded") saw_wall = true;
  }
  EXPECT_TRUE(saw_wall);
  EXPECT_TRUE(result.rebuild.ok);
  ASSERT_NE(ctx.geometry.last_build_request(), nullptr);
  EXPECT_EQ(ctx.geometry.last_build_request()->semantics.document_id, "doc_1");
  const auto saved = ctx.store.load("doc_1");
  ASSERT_TRUE(saved);
  EXPECT_EQ(saved->storeys[0].walls.size(), 1u);
}

TEST(Handlers, AddOpeningEmitsEvent) {
  Ctx ctx;
  ctx.add_wall.execute(south_wall(ctx.storey_id));
  AddOpeningCommand opening;
  opening.document_id = "doc_1";
  opening.storey_id = ctx.storey_id;
  opening.wall_id = "wall_s";
  opening.opening_id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width_mm = 900;
  opening.height_mm = 2100;
  opening.offset_mm = 800;
  const auto result = ctx.add_opening.execute(opening);
  bool saw = false;
  for (const auto& event : result.events) {
    if (std::string(event_type(event)) == "OpeningAdded") saw = true;
  }
  EXPECT_TRUE(saw);
}

TEST(Handlers, SetMeasurementWritesLaserAndResizes) {
  Ctx ctx;
  ctx.add_wall.execute(south_wall(ctx.storey_id));
  AddOpeningCommand opening;
  opening.document_id = "doc_1";
  opening.storey_id = ctx.storey_id;
  opening.wall_id = "wall_s";
  opening.opening_id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width_mm = 800;
  opening.height_mm = 2100;
  opening.offset_mm = 800;
  ctx.add_opening.execute(opening);
  SetMeasurementCommand measurement;
  measurement.document_id = "doc_1";
  measurement.measurement_id = "m_door";
  measurement.value_mm = 900;
  measurement.source = MeasurementSource::Laser;
  measurement.instrument_id = "laser_sku_x";
  measurement.target = {{"opening", "op_door", "width"}};
  ctx.set_measurement.execute(measurement);
  const auto saved = ctx.store.load("doc_1");
  ASSERT_TRUE(saved);
  EXPECT_EQ(saved->measurements[0].source, MeasurementSource::Laser);
  EXPECT_EQ(saved->measurements[0].value_mm, 900);
  EXPECT_EQ(saved->storeys[0].walls[0].openings[0].width_mm, 900);
}

TEST(Handlers, RebuildPolicyReceivesFault) {
  Ctx ctx;
  ctx.geometry.fail_with({FaultCode::NotClosed, "room not closed", {ctx.storey_id}});
  const auto result = ctx.add_wall.execute(south_wall(ctx.storey_id));
  EXPECT_FALSE(result.rebuild.ok);
  EXPECT_EQ(result.rebuild.fault.code, FaultCode::NotClosed);
}
