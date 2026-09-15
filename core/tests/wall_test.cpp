#include <gtest/gtest.h>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/domain/wall.hpp"

using toporoom::domain::DomainError;
using toporoom::domain::LengthMm;
using toporoom::domain::PointMm;
using toporoom::domain::Wall;
using toporoom::domain::WallKind;
using toporoom::domain::WallProps;

TEST(Wall, RecordsGeometry) {
  WallProps props;
  props.id = "wall_a";
  props.start = PointMm::of(0, 0);
  props.end = PointMm::of(4000, 0);
  props.thickness = LengthMm::of(200);
  props.height = LengthMm::of(2800);
  props.kind = WallKind::Exterior;
  const Wall wall = Wall::create(props);
  EXPECT_EQ(wall.id(), "wall_a");
  EXPECT_EQ(wall.length_mm().value(), 4000);
  EXPECT_EQ(wall.kind(), WallKind::Exterior);
  EXPECT_TRUE(wall.openings().empty());
}

TEST(Wall, RejectsZeroLength) {
  WallProps props;
  props.id = "wall_zero";
  props.start = PointMm::of(10, 10);
  props.end = PointMm::of(10, 10);
  props.thickness = LengthMm::of(200);
  props.height = LengthMm::of(2800);
  props.kind = WallKind::Interior;
  EXPECT_THROW(Wall::create(props), DomainError);
}

TEST(Wall, RejectsNonPositiveThickness) {
  WallProps props;
  props.id = "wall_thin";
  props.start = PointMm::of(0, 0);
  props.end = PointMm::of(4000, 0);
  props.thickness = LengthMm::of(0);
  props.height = LengthMm::of(2800);
  props.kind = WallKind::Interior;
  EXPECT_THROW(Wall::create(props), DomainError);
}
