#include <cmath>

#include <gtest/gtest.h>

#include "toporoom/adapters/floor_plan_raster_geom.hpp"
#include "toporoom/adapters/floor_plan_vision_adapters.hpp"
#include "toporoom/c_api/toporoom.h"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"

using toporoom::adapters::analyze_floor_plan_raster;
using toporoom::adapters::apply_vision_result;
using toporoom::adapters::classify_window_subtype;
using toporoom::adapters::close_exterior_loop;
using toporoom::adapters::detected_wall_to_seg;
using toporoom::adapters::largest_exterior_gap_mm;
using toporoom::adapters::load_raster_image;
using toporoom::adapters::merge_collinear_segments;
using toporoom::adapters::RasterImage;
using toporoom::adapters::RasterSeg;
using toporoom::adapters::snap_endpoints;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::WindowSubtype;
using toporoom::domain::WallKind;

namespace {

RasterSeg hseg(double x0, double x1, double y, WallKind kind = WallKind::ShearWall) {
  RasterSeg s;
  s.x0 = x0;
  s.y0 = y;
  s.x1 = x1;
  s.y1 = y;
  s.thickness_mm = 200;
  s.kind = kind;
  return s;
}

RasterSeg vseg(double x, double y0, double y1, WallKind kind = WallKind::ShearWall) {
  RasterSeg s;
  s.x0 = x;
  s.y0 = y0;
  s.x1 = x;
  s.y1 = y1;
  s.thickness_mm = 200;
  s.kind = kind;
  return s;
}

std::string fixture_png() {
  return std::string(TOPOROOM_FIXTURE_DIR) + "/vision/apt-plan-user-01.png";
}

}  // namespace

TEST(RasterGeom, MergeCollinearJoinsFragments) {
  const std::vector<RasterSeg> in = {hseg(0, 1000, 0), hseg(1120, 2000, 15)};
  const auto out = merge_collinear_segments(in, 150, 200);
  ASSERT_EQ(out.size(), 1u);
  EXPECT_NEAR(std::min(out[0].x0, out[0].x1), 0.0, 20.0);
  EXPECT_NEAR(std::max(out[0].x0, out[0].x1), 2000.0, 20.0);
}

TEST(RasterGeom, SnapEndpointsJoinsCornerGap) {
  const std::vector<RasterSeg> in = {hseg(0, 4000, 0), vseg(4120, 80, 3000)};
  const auto out = snap_endpoints(in, 150);
  ASSERT_EQ(out.size(), 2u);
  const double hx = std::max(out[0].x0, out[0].x1);
  const double vx = out[1].x0;
  EXPECT_NEAR(hx, vx, 1.0);
  EXPECT_NEAR(out[0].y0, out[1].y0, 1.0);
}

TEST(RasterGeom, CloseExteriorLoopFillsDegreeOneGap) {
  std::vector<RasterSeg> open = {
      hseg(0, 4000, 0),
      vseg(4000, 0, 3000),
      hseg(0, 4000, 3000),
      vseg(0, 400, 3000),  // 400 mm gap at (0,0)-(0,400)
  };
  const auto closed = close_exterior_loop(open, 50, 600);
  EXPECT_GE(closed.size(), 4u);
  EXPECT_LE(largest_exterior_gap_mm(closed, 50), 150.0);
}

TEST(RasterGeom, CloseExteriorLoopFillsLCorner) {
  // Rectangle missing an L-shaped southwest corner.
  std::vector<RasterSeg> open = {
      hseg(400, 4000, 0),
      vseg(4000, 0, 3000),
      hseg(0, 4000, 3000),
      vseg(0, 400, 3000),
  };
  const auto closed = close_exterior_loop(open, 50, 800);
  EXPECT_LE(largest_exterior_gap_mm(closed, 50), 150.0);
}

TEST(RasterGeom, SplitAtNodesMakesTeeNotAGap) {
  std::vector<RasterSeg> box = {
      hseg(0, 4000, 0),
      vseg(4000, 0, 3000),
      hseg(0, 4000, 3000),
      vseg(0, 0, 3000),
      vseg(2000, 0, 1500),
  };
  EXPECT_LE(largest_exterior_gap_mm(box, 50), 150.0);
}

TEST(RasterGeom, ClassifyWindowSubtypeBayAndFloorCeiling) {
  EXPECT_EQ(classify_window_subtype(900, 1400, 2800, false), WindowSubtype::Standard);
  EXPECT_EQ(classify_window_subtype(0, 2600, 2800, false), WindowSubtype::FloorCeiling);
  EXPECT_EQ(classify_window_subtype(900, 1400, 2800, true), WindowSubtype::Bay);
  EXPECT_EQ(classify_window_subtype(0, 2700, 2800, true), WindowSubtype::Bay);
}

TEST(FloorPlanRaster, GoldenExteriorIsClosedLoop) {
  RasterImage image;
  std::string err;
  ASSERT_TRUE(load_raster_image(fixture_png(), {}, &image, &err)) << err;
  const auto detected = analyze_floor_plan_raster(image);
  ASSERT_TRUE(detected.ok) << detected.error;
  std::vector<RasterSeg> segs;
  segs.reserve(detected.walls.size());
  for (const auto& w : detected.walls) segs.push_back(detected_wall_to_seg(w));
  EXPECT_LE(largest_exterior_gap_mm(segs, 120), 150.0);

  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_closed"});
  ASSERT_EQ(apply_vision_result(doc, detected, &err), 0) << err;
  char status[32] = {};
  char rerr[256] = {};
  TopoRoomDocument* cdoc = toporoom_document_create("doc_c_closed");
  ASSERT_NE(cdoc, nullptr);
  TopoRoomVisionCounts counts{};
  ASSERT_EQ(toporoom_vision_import_image(cdoc, fixture_png().c_str(), &counts, rerr, sizeof(rerr)),
            0)
      << rerr;
  EXPECT_EQ(toporoom_document_rebuild_status(cdoc, status, sizeof(status), rerr, sizeof(rerr)), 0)
      << rerr;
  EXPECT_STREQ(status, "ok");
  toporoom_document_destroy(cdoc);
}

TEST(FloorPlanRaster, GoldenHasBayAndFloorCeilingWindows) {
  RasterImage image;
  std::string err;
  ASSERT_TRUE(load_raster_image(fixture_png(), {}, &image, &err)) << err;
  const auto detected = analyze_floor_plan_raster(image);
  ASSERT_TRUE(detected.ok) << detected.error;
  int bay = 0;
  int floor_c = 0;
  for (const auto& op : detected.openings) {
    if (op.kind != toporoom::domain::OpeningKind::Window) continue;
    if (op.subtype == WindowSubtype::Bay) ++bay;
    if (op.subtype == WindowSubtype::FloorCeiling) ++floor_c;
  }
  EXPECT_GE(bay, 1);
  EXPECT_GE(floor_c, 1);

  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_win_sub"});
  ASSERT_EQ(apply_vision_result(doc, detected, &err), 0) << err;
  int ir_bay = 0;
  int ir_fc = 0;
  for (const auto& wall : doc.to_scene_ir().storeys[0].walls) {
    for (const auto& op : wall.openings) {
      if (op.subtype == WindowSubtype::Bay) ++ir_bay;
      if (op.subtype == WindowSubtype::FloorCeiling) ++ir_fc;
    }
  }
  EXPECT_GE(ir_bay, 1);
  EXPECT_GE(ir_fc, 1);
}
