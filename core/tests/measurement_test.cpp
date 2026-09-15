#include <gtest/gtest.h>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

using toporoom::domain::AddOpeningProps;
using toporoom::domain::AddWallProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::DomainError;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::is_measurement_source;
using toporoom::domain::LengthMm;
using toporoom::domain::MeasurementSource;
using toporoom::domain::OpeningKind;
using toporoom::domain::PointMm;
using toporoom::domain::SetMeasurementProps;
using toporoom::domain::WallKind;

TEST(Measurements, FrozenSources) {
  EXPECT_TRUE(is_measurement_source("laser"));
  EXPECT_TRUE(is_measurement_source("typed"));
  EXPECT_TRUE(is_measurement_source("depth_fit"));
  EXPECT_FALSE(is_measurement_source("rf_ble"));
}

TEST(Measurements, RecordsLaserOnOpening) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  const auto storey_id = doc.storeys()[0].id();
  AddWallProps wall;
  wall.storey_id = storey_id;
  wall.id = "wall_s";
  wall.start = PointMm::of(0, 0);
  wall.end = PointMm::of(4000, 0);
  wall.thickness = LengthMm::of(200);
  wall.height = LengthMm::of(2800);
  wall.kind = WallKind::Exterior;
  doc.add_wall(wall);
  AddOpeningProps opening;
  opening.storey_id = storey_id;
  opening.wall_id = "wall_s";
  opening.id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width = LengthMm::of(800);
  opening.height = LengthMm::of(2100);
  opening.offset_along_wall = LengthMm::of(800);
  doc.add_opening(opening);
  SetMeasurementProps measurement;
  measurement.id = "m_door_width";
  measurement.value = LengthMm::of(900);
  measurement.source = MeasurementSource::Laser;
  measurement.instrument_id = "laser_sku_x";
  measurement.target = {{"opening", "op_door", "width"}};
  doc.set_measurement(measurement);
  ASSERT_FALSE(doc.measurements().empty());
  EXPECT_EQ(doc.measurements()[0].source, MeasurementSource::Laser);
  EXPECT_EQ(doc.measurements()[0].value_mm, 900);
  EXPECT_EQ(doc.storeys()[0].walls()[0].openings()[0].width().value(), 900);
}

TEST(Measurements, DepthFitDoesNotOverwriteLaser) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  SetMeasurementProps laser;
  laser.id = "m_axis";
  laser.value = LengthMm::of(4000);
  laser.source = MeasurementSource::Laser;
  laser.instrument_id = "laser_sku_x";
  laser.between = {"lm_a", "lm_b"};
  doc.set_measurement(laser);
  SetMeasurementProps depth;
  depth.id = "m_axis";
  depth.value = LengthMm::of(4012);
  depth.source = MeasurementSource::DepthFit;
  EXPECT_THROW(doc.set_measurement(depth), DomainError);
  EXPECT_EQ(doc.measurements()[0].source, MeasurementSource::Laser);
  EXPECT_EQ(doc.measurements()[0].value_mm, 4000);
}

TEST(Measurements, TypedCanReplaceTyped) {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_1"});
  SetMeasurementProps first;
  first.id = "m_height";
  first.value = LengthMm::of(2700);
  first.source = MeasurementSource::Typed;
  first.target = {{"storey", doc.storeys()[0].id(), "height"}};
  doc.set_measurement(first);
  SetMeasurementProps second = first;
  second.value = LengthMm::of(2800);
  doc.set_measurement(second);
  EXPECT_EQ(doc.measurements()[0].value_mm, 2800);
  EXPECT_EQ(doc.storeys()[0].height().value(), 2800);
}
