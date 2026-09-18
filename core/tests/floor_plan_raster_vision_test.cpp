#include <cmath>
#include <fstream>
#include <nlohmann/json.hpp>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/adapters/floor_plan_vision_adapters.hpp"
#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/c_api/toporoom.h"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"

using toporoom::adapters::analyze_floor_plan_raster;
using toporoom::adapters::apply_vision_result;
using toporoom::adapters::fill_vision_counts;
using toporoom::adapters::load_raster_image;
using toporoom::adapters::RasterImage;
using toporoom::adapters::RasterVisionAdapter;
using toporoom::adapters::scene_ir_to_json;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::OpeningKind;
using toporoom::domain::WallKind;
using toporoom::ports::VisionRequest;

namespace {

std::string fixture_png() {
  return std::string(TOPOROOM_FIXTURE_DIR) + "/vision/apt-plan-user-01.png";
}

std::string expected_json_path() {
  return std::string(TOPOROOM_FIXTURE_DIR) + "/vision/apt-plan-user-01.expected.json";
}

nlohmann::json load_expected() {
  std::ifstream in(expected_json_path());
  nlohmann::json j;
  in >> j;
  return j;
}

}  // namespace

TEST(FloorPlanRaster, FixtureLoadsPng) {
  RasterImage image;
  std::string err;
  ASSERT_TRUE(load_raster_image(fixture_png(), {}, &image, &err)) << err;
  EXPECT_GE(image.width, 600);
  EXPECT_GE(image.height, 600);
}

TEST(FloorPlanRaster, GoldenApartmentHasShearMasonryDoorsWindows) {
  RasterImage image;
  std::string err;
  ASSERT_TRUE(load_raster_image(fixture_png(), {}, &image, &err)) << err;
  const auto detected = analyze_floor_plan_raster(image);
  ASSERT_TRUE(detected.ok) << detected.error;
  EXPECT_EQ(detected.adapter_id, "raster");
  int shear = 0;
  int masonry = 0;
  int doors = 0;
  int windows = 0;
  fill_vision_counts(detected, &shear, &masonry, &doors, &windows);
  const auto exp = load_expected();
  EXPECT_GE(shear, exp.at("min_shear").get<int>());
  EXPECT_GE(masonry, exp.at("min_masonry").get<int>());
  EXPECT_GE(doors, exp.at("min_doors").get<int>());
  EXPECT_GE(windows, exp.at("min_windows").get<int>());
  EXPECT_GE(static_cast<int>(detected.columns.size()), exp.at("min_columns").get<int>());
  EXPECT_GE(detected.mm_per_px, exp.at("mm_per_px_min").get<double>());
  EXPECT_LE(detected.mm_per_px, exp.at("mm_per_px_max").get<double>());
  double min_x = 1e9;
  double max_x = -1e9;
  for (const auto& wall : detected.walls) {
    min_x = std::min(min_x, std::min(wall.start_x, wall.end_x));
    max_x = std::max(max_x, std::max(wall.start_x, wall.end_x));
  }
  const double width = max_x - min_x;
  EXPECT_GE(width, exp.at("plan_width_mm_min").get<double>());
  EXPECT_LE(width, exp.at("plan_width_mm_max").get<double>());
  EXPECT_NE(width, 4000.0);
}

TEST(FloorPlanRaster, ApplyAndSceneIrRoundTripRebuildOk) {
  RasterImage image;
  std::string err;
  ASSERT_TRUE(load_raster_image(fixture_png(), {}, &image, &err)) << err;
  const auto detected = analyze_floor_plan_raster(image);
  ASSERT_TRUE(detected.ok) << detected.error;
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_raster_golden"});
  ASSERT_EQ(apply_vision_result(doc, detected, &err), 0) << err;
  const auto exp = load_expected();
  ASSERT_FALSE(doc.storeys().empty());
  const auto& storey = doc.storeys()[0];
  EXPECT_GE(static_cast<int>(storey.walls().size()), exp.at("min_walls_applied").get<int>());
  int openings = 0;
  int shear = 0;
  int masonry = 0;
  for (const auto& wall : storey.walls()) {
    openings += static_cast<int>(wall.openings().size());
    if (wall.kind() == WallKind::ShearWall) ++shear;
    else ++masonry;
  }
  EXPECT_GE(openings, exp.at("min_openings_applied").get<int>());
  EXPECT_GE(shear, exp.at("min_shear").get<int>());
  EXPECT_GE(masonry, 1);

  const std::string json = scene_ir_to_json(doc.to_scene_ir());
  EXPECT_NE(json.find("shearWall"), std::string::npos);
  EXPECT_NE(json.find("masonry"), std::string::npos);
  EXPECT_NE(json.find("\"door\""), std::string::npos);
  EXPECT_NE(json.find("\"window\""), std::string::npos);
  auto loaded = FloorPlanDocument::from_scene_ir(
      toporoom::adapters::load_scene_ir_json(json));
  const std::string json2 = scene_ir_to_json(loaded.to_scene_ir());
  EXPECT_EQ(loaded.storeys()[0].walls().size(), storey.walls().size());
  EXPECT_NE(json2.find("shearWall"), std::string::npos);

  TopoRoomDocument* cdoc = toporoom_document_create("doc_c_raster");
  ASSERT_NE(cdoc, nullptr);
  TopoRoomVisionCounts counts{};
  char cerr[256] = {};
  ASSERT_EQ(toporoom_vision_import_image(cdoc, fixture_png().c_str(), &counts, cerr, sizeof(cerr)),
            0)
      << cerr;
  EXPECT_GE(counts.wall_count, exp.at("min_walls_applied").get<int>());
  EXPECT_GE(counts.opening_count, exp.at("min_openings_applied").get<int>());
  EXPECT_GE(counts.shear_count, exp.at("min_shear").get<int>());
  EXPECT_GE(counts.masonry_count, exp.at("min_masonry").get<int>());
  EXPECT_GE(counts.door_count, exp.at("min_doors").get<int>());
  EXPECT_GE(counts.window_count, exp.at("min_windows").get<int>());
  char status[32] = {};
  char rerr[256] = {};
  EXPECT_EQ(toporoom_document_rebuild_status(cdoc, status, sizeof(status), rerr, sizeof(rerr)), 0)
      << rerr;
  EXPECT_STREQ(status, "ok");
  toporoom_document_destroy(cdoc);
}

TEST(FloorPlanRaster, GoldenSceneIrFileRoundTrip) {
  const std::string path =
      std::string(TOPOROOM_FIXTURE_DIR) + "/vision/apt-plan-user-01.sceneir.json";
  char err[256] = {};
  TopoRoomDocument* doc = toporoom_document_load(path.c_str(), err, sizeof(err));
  ASSERT_NE(doc, nullptr) << err;
  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  const std::string text(json);
  toporoom_string_free(json);
  EXPECT_NE(text.find("shearWall"), std::string::npos);
  EXPECT_NE(text.find("masonry"), std::string::npos);
  EXPECT_NE(text.find("\"door\""), std::string::npos);
  EXPECT_NE(text.find("\"window\""), std::string::npos);
  char status[32] = {};
  EXPECT_EQ(toporoom_document_rebuild_status(doc, status, sizeof(status), err, sizeof(err)), 0)
      << err;
  EXPECT_STREQ(status, "ok");
  toporoom_document_destroy(doc);
}

TEST(FloorPlanRaster, AdapterRejectsMissingFile) {
  RasterVisionAdapter raster;
  VisionRequest req;
  req.image_uri = "/no/such/toporoom_plan.png";
  const auto r = raster.detect_walls(req);
  EXPECT_FALSE(r.ok);
}

TEST(FloorPlanRaster, MissingPathCApiFails) {
  TopoRoomDocument* doc = toporoom_document_create("doc_missing_raster");
  ASSERT_NE(doc, nullptr);
  char err[256] = {};
  TopoRoomVisionCounts counts{};
  EXPECT_NE(toporoom_vision_import_image(doc, "/no/such/toporoom_plan.png", &counts, err,
                                         sizeof(err)),
            0);
  toporoom_document_destroy(doc);
}

TEST(FloorPlanRaster, ScaleOverrideHonorsCalibration) {
  RasterImage image;
  std::string err;
  ASSERT_TRUE(load_raster_image(fixture_png(), {}, &image, &err)) << err;
  toporoom::adapters::RasterAnalyzeOptions opt;
  opt.mm_per_px_override = 20.0;
  const auto detected = analyze_floor_plan_raster(image, opt);
  ASSERT_TRUE(detected.ok) << detected.error;
  EXPECT_NEAR(detected.mm_per_px, 20.0, 0.05);
  TopoRoomDocument* cdoc = toporoom_document_create("doc_scale_cal");
  ASSERT_NE(cdoc, nullptr);
  TopoRoomVisionCounts counts{};
  char cerr[256] = {};
  ASSERT_EQ(toporoom_vision_import_image_ex(cdoc, fixture_png().c_str(), 20.0, &counts, cerr,
                                           sizeof(cerr)),
            0)
      << cerr;
  EXPECT_NEAR(counts.mm_per_px, 20.0, 0.05);
  toporoom_document_destroy(cdoc);
}
