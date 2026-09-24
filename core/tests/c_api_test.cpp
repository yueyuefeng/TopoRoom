#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/c_api/toporoom.h"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif

namespace {

std::string read_fixture(const char* name) {
  std::ifstream in(std::string(TOPOROOM_FIXTURE_DIR) + "/" + name);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return buffer.str();
}

}  // namespace

TEST(CApi, VersionAndDocumentRoundTrip) {
  EXPECT_STREQ(toporoom_version(), "0.1.0");
  TopoRoomDocument* doc = toporoom_document_create("doc_c");
  ASSERT_NE(doc, nullptr);
  char storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, storey, sizeof(storey)), 0);
  EXPECT_STREQ(storey, "storey_1");
  char err[256] = {};
  const int rc = toporoom_document_add_wall(doc, storey, "wall_s", 0, 0, 4000, 0, 200,
                                            2800, err, sizeof(err));
  EXPECT_EQ(rc, 0) << err;
  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  const std::string text(json);
  EXPECT_NE(text.find("wall_s"), std::string::npos);
  EXPECT_NE(text.find("toporoom.sceneir"), std::string::npos);
  toporoom_string_free(json);
  toporoom_document_destroy(doc);
}

TEST(CApi, OpeningMeasurementGuideAndEvidence) {
  TopoRoomDocument* doc = toporoom_document_create("doc_open");
  ASSERT_NE(doc, nullptr);
  char storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, storey, sizeof(storey)), 0);
  char err[256] = {};
  ASSERT_EQ(toporoom_document_add_wall(doc, storey, "wall_s", 0, 0, 4000, 0, 200, 2800,
                                       err, sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_add_opening(doc, storey, "wall_s", "op_door", "door", 900,
                                          2100, 800, 0, err, sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_set_measurement(doc, "m_door", 900, "typed", nullptr,
                                              nullptr, "opening", "op_door", "width", err,
                                              sizeof(err)),
            0)
      << err;

  TopoRoomGuide* guide = toporoom_guide_create();
  ASSERT_NE(guide, nullptr);
  toporoom_guide_mark_host_ok(guide, 1);
  EXPECT_STREQ(toporoom_guide_phase(guide), "draw_walls");
  toporoom_guide_destroy(guide);

  TopoRoomEvidence* pack = toporoom_evidence_create("doc_open");
  ASSERT_NE(pack, nullptr);
  EXPECT_EQ(toporoom_evidence_empty(pack), 1);
  ASSERT_EQ(toporoom_evidence_attach(pack, "note_1", "note", ""), 0);
  EXPECT_EQ(toporoom_evidence_empty(pack), 0);
  EXPECT_EQ(toporoom_evidence_detach(pack, "note_1"), 1);
  EXPECT_EQ(toporoom_evidence_empty(pack), 1);
  toporoom_evidence_destroy(pack);
  toporoom_document_destroy(doc);
}

TEST(CApi, SceneIrSaveLoadRoundTrip) {
  TopoRoomDocument* doc = toporoom_document_create("doc_io");
  ASSERT_NE(doc, nullptr);
  char storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, storey, sizeof(storey)), 0);
  char err[256] = {};
  ASSERT_EQ(toporoom_document_add_wall(doc, storey, "wall_s", 0, 0, 4000, 0, 200, 2800,
                                       err, sizeof(err)),
            0)
      << err;
  const auto path =
      (std::filesystem::temp_directory_path() / "toporoom_doc_io.sceneir.json").string();
  ASSERT_EQ(toporoom_document_save(doc, path.c_str(), err, sizeof(err)), 0) << err;
  toporoom_document_destroy(doc);

  TopoRoomDocument* loaded = toporoom_document_load(path.c_str(), err, sizeof(err));
  ASSERT_NE(loaded, nullptr) << err;
  char* json = toporoom_document_to_sceneir_json(loaded);
  ASSERT_NE(json, nullptr);
  EXPECT_NE(std::string(json).find("wall_s"), std::string::npos);
  EXPECT_NE(std::string(json).find("doc_io"), std::string::npos);
  TopoRoomDocument* from_text = toporoom_document_from_sceneir_json(json, err, sizeof(err));
  toporoom_string_free(json);
  ASSERT_NE(from_text, nullptr) << err;
  char loaded_storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(from_text, loaded_storey, sizeof(loaded_storey)),
            0);
  EXPECT_STREQ(loaded_storey, "storey_1");
  toporoom_document_destroy(from_text);
  toporoom_document_destroy(loaded);

  const auto fixture = std::string(TOPOROOM_FIXTURE_DIR) +
                       "/rect-room-v02-archway-clearheight.sceneir.json";
  TopoRoomDocument* v02 = toporoom_document_load(fixture.c_str(), err, sizeof(err));
  ASSERT_NE(v02, nullptr) << err;
  char* v02_json = toporoom_document_to_sceneir_json(v02);
  ASSERT_NE(v02_json, nullptr);
  EXPECT_NE(std::string(v02_json).find("archway"), std::string::npos);
  EXPECT_NE(std::string(v02_json).find("clearHeightMm"), std::string::npos);
  toporoom_string_free(v02_json);
  toporoom_document_destroy(v02);
}

TEST(CApi, DocumentIdAndRebuildStatusAfterFakeOneRoom) {
  TopoRoomDocument* doc = toporoom_document_create("doc_status");
  ASSERT_NE(doc, nullptr);
  char id[64] = {};
  ASSERT_EQ(toporoom_document_id(doc, id, sizeof(id)), 0);
  EXPECT_STREQ(id, "doc_status");

  TopoRoomGuide* guide = toporoom_guide_create();
  ASSERT_NE(guide, nullptr);
  char err[256] = {};
  ASSERT_EQ(toporoom_debug_fake_one_room(doc, guide, nullptr, err, sizeof(err)), 0) << err;

  char status[32] = {};
  ASSERT_EQ(toporoom_document_rebuild_status(doc, status, sizeof(status), err, sizeof(err)), 0)
      << err;
  EXPECT_STREQ(status, "ok");
  toporoom_guide_destroy(guide);
  toporoom_document_destroy(doc);
}

TEST(CApi, IosExternalDepthOutOfP0) { EXPECT_EQ(toporoom_ios_external_depth_in_p0(), 0); }

TEST(CApi, WhitelistAndReleaseTrainJson) {
  const auto whitelist = read_fixture("android-whitelist.v1.json");
  EXPECT_EQ(toporoom_whitelist_allows(whitelist.c_str(), "Pixel 8", 34, "dabai_dcw", "2460",
                                      "powered_hub_a", "0.1.0"),
            1);
  EXPECT_EQ(toporoom_whitelist_allows(whitelist.c_str(), "sdk_gphone64_x86_64", 34, "fake",
                                      "replay", "none", "0.1.0"),
            0);
  const auto train = read_fixture("release-train.v1.json");
  EXPECT_EQ(toporoom_release_train_matches(train.c_str(), "0.1.0", "fake", "replay", 1, "0.1.0"),
            1);
  EXPECT_EQ(
      toporoom_release_train_matches(train.c_str(), "0.1.0", "dabai_dcw", "2460", 1, "0.1.0"),
      1);
  EXPECT_EQ(toporoom_release_train_matches(train.c_str(), "0.1.0", "orbbec_gemini_e", "3460", 1,
                                           "0.1.0"),
            0);
  EXPECT_EQ(toporoom_release_train_matches(train.c_str(), "0.2.0", "fake", "replay", 1, "0.1.0"),
            0);
}

TEST(CApi, HubGattGoldenBytes) {
  unsigned char cmd[4] = {};
  ASSERT_EQ(toporoom_hub_pack_measure_cmd(cmd, 4, 1000), 0);
  EXPECT_EQ(cmd[0], 0x01);
  EXPECT_EQ(cmd[1], 0x01);
  EXPECT_EQ(cmd[2], 0xE8);
  EXPECT_EQ(cmd[3], 0x03);
  const unsigned char notify[12] = {0x84, 0x03, 0x00, 0x00, 0x00, 0x01,
                                    0x01, 0x00, 0x00, 0x00, 0x00, 0x00};
  double mm = 0;
  ASSERT_EQ(toporoom_hub_parse_length_notify_mm(notify, 12, &mm), 0);
  EXPECT_EQ(mm, 900);
  const unsigned char rf[12] = {0x84, 0x03, 0x00, 0x00, 0x00, 0x00,
                                0x01, 0x00, 0x00, 0x00, 0x00, 0x00};
  EXPECT_NE(toporoom_hub_parse_length_notify_mm(rf, 12, &mm), 0);
}

TEST(CApi, FreeDrawClosedRectangleCommands) {
  TopoRoomDocument* doc = toporoom_document_create("doc_free_draw");
  ASSERT_NE(doc, nullptr);
  char storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, storey, sizeof(storey)), 0);
  char err[256] = {};
  ASSERT_EQ(toporoom_document_add_wall(doc, storey, "wall_d1", 0, 0, 4000, 0, 200, 2800, err,
                                       sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_add_wall(doc, storey, "wall_d2", 4000, 0, 4000, 3000, 200, 2800,
                                       err, sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_add_wall(doc, storey, "wall_d3", 4000, 3000, 0, 3000, 200, 2800,
                                       err, sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_add_wall(doc, storey, "wall_d4", 0, 3000, 0, 0, 200, 2800, err,
                                       sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_move_wall(doc, storey, "wall_d2", 4000, 0, 4000, 3200, err,
                                        sizeof(err)),
            0)
      << err;
  ASSERT_EQ(toporoom_document_resize_wall(doc, storey, "wall_d1", 4200, err, sizeof(err)), 0)
      << err;
  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  const std::string text(json);
  toporoom_string_free(json);
  EXPECT_NE(text.find("wall_d1"), std::string::npos);
  EXPECT_NE(text.find("wall_d2"), std::string::npos);
  EXPECT_NE(text.find("wall_d3"), std::string::npos);
  EXPECT_NE(text.find("wall_d4"), std::string::npos);
  ASSERT_EQ(toporoom_document_delete_wall(doc, storey, "wall_d3", err, sizeof(err)), 0) << err;
  json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  EXPECT_EQ(std::string(json).find("wall_d3"), std::string::npos);
  toporoom_string_free(json);
  toporoom_document_destroy(doc);
}

TEST(CApi, ArScanClosedPolylineCommands) {
  TopoRoomDocument* doc = toporoom_document_create("doc_ar_scan");
  ASSERT_NE(doc, nullptr);
  char storey[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(doc, storey, sizeof(storey)), 0);
  char err[256] = {};
  const double rect[] = {0, 0, 4000, 0, 4000, 3000, 0, 3000};
  int added = 0;
  ASSERT_EQ(toporoom_document_add_polyline_walls(doc, storey, "wall_a", 1, rect, 4, 1, 200,
                                                 2800, 200, &added, err, sizeof(err)),
            0)
      << err;
  EXPECT_EQ(added, 4);
  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  const std::string text(json);
  toporoom_string_free(json);
  EXPECT_NE(text.find("wall_a1"), std::string::npos);
  EXPECT_NE(text.find("wall_a2"), std::string::npos);
  EXPECT_NE(text.find("wall_a3"), std::string::npos);
  EXPECT_NE(text.find("wall_a4"), std::string::npos);

  TopoRoomDocument* near_doc = toporoom_document_create("doc_ar_near");
  ASSERT_NE(near_doc, nullptr);
  char storey2[64] = {};
  ASSERT_EQ(toporoom_document_first_storey_id(near_doc, storey2, sizeof(storey2)), 0);
  const double near_closed[] = {0, 0, 4000, 0, 4000, 3000, 0, 3000, 80, 40};
  int near_added = 0;
  ASSERT_EQ(toporoom_document_add_polyline_walls(near_doc, storey2, "wall_a", 1, near_closed,
                                                 5, 1, 200, 2800, 200, &near_added, err,
                                                 sizeof(err)),
            0)
      << err;
  EXPECT_EQ(near_added, 4);
  json = toporoom_document_to_sceneir_json(near_doc);
  ASSERT_NE(json, nullptr);
  EXPECT_NE(std::string(json).find("wall_a4"), std::string::npos);
  toporoom_string_free(json);

  int none = -1;
  EXPECT_NE(toporoom_document_add_polyline_walls(doc, storey, "wall_x", 1, rect, 1, 1, 200,
                                                 2800, 200, &none, err, sizeof(err)),
            0);
  EXPECT_EQ(none, 0);

  toporoom_document_destroy(near_doc);
  toporoom_document_destroy(doc);
}
