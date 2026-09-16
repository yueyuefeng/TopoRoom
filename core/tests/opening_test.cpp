#include <gtest/gtest.h>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/opening.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/domain/wall.hpp"

using toporoom::domain::DomainError;
using toporoom::domain::LengthMm;
using toporoom::domain::Opening;
using toporoom::domain::OpeningKind;
using toporoom::domain::OpeningProps;
using toporoom::domain::PointMm;
using toporoom::domain::Wall;
using toporoom::domain::WallKind;
using toporoom::domain::WallProps;

namespace {

Wall host_wall() {
  WallProps props;
  props.id = "wall_host";
  props.start = PointMm::of(0, 0);
  props.end = PointMm::of(4000, 0);
  props.thickness = LengthMm::of(200);
  props.height = LengthMm::of(2800);
  props.kind = WallKind::Exterior;
  return Wall::create(props);
}

OpeningProps door_props(const char* id, double width, double height, double offset,
                        double sill) {
  OpeningProps props;
  props.id = id;
  props.kind = OpeningKind::Door;
  props.width = LengthMm::of(width);
  props.height = LengthMm::of(height);
  props.offset_along_wall = LengthMm::of(offset);
  props.sill_height = LengthMm::of(sill);
  return props;
}

}  // namespace

TEST(Opening, PlacesDoorOnHostWall) {
  const Opening opening = Opening::create(door_props("op_door", 900, 2100, 500, 0));
  const Wall wall = host_wall().host_opening(opening);
  ASSERT_EQ(wall.openings().size(), 1u);
  EXPECT_EQ(wall.openings()[0].id(), "op_door");
}

TEST(Opening, RejectsOpeningPastWallLength) {
  const Opening opening = Opening::create(door_props("op_wide", 2000, 2100, 2500, 0));
  EXPECT_THROW(host_wall().host_opening(opening), DomainError);
}

TEST(Opening, RejectsOpeningTallerThanWall) {
  OpeningProps props = door_props("op_tall", 900, 3000, 200, 900);
  props.kind = OpeningKind::Window;
  const Opening opening = Opening::create(props);
  EXPECT_THROW(host_wall().host_opening(opening), DomainError);
}

TEST(Opening, DistinguishesArchwayFromDoor) {
  OpeningProps arch = door_props("op_arch", 1200, 2100, 200, 0);
  arch.kind = OpeningKind::Archway;
  const Opening opening = Opening::create(arch);
  EXPECT_EQ(opening.kind(), OpeningKind::Archway);
  EXPECT_NE(opening.kind(), OpeningKind::Door);
  const Wall wall = host_wall().host_opening(opening);
  EXPECT_EQ(wall.openings()[0].kind(), OpeningKind::Archway);
}
