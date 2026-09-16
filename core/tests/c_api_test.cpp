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

TEST(CApi, IosExternalDepthOutOfP0) { EXPECT_EQ(toporoom_ios_external_depth_in_p0(), 0); }

TEST(CApi, WhitelistAndReleaseTrainJson) {
  const auto whitelist = read_fixture("android-whitelist.v1.json");
  EXPECT_EQ(toporoom_whitelist_allows(whitelist.c_str(), "Pixel 8", 34, "orbbec_gemini_e",
                                      "1.2.0", "powered_hub_a", "0.1.0"),
            1);
  EXPECT_EQ(toporoom_whitelist_allows(whitelist.c_str(), "sdk_gphone64_x86_64", 34,
                                      "orbbec_gemini_e", "1.2.0", "none", "0.1.0"),
            0);
  const auto train = read_fixture("release-train.v1.json");
  EXPECT_EQ(toporoom_release_train_matches(train.c_str(), "0.1.0", "orbbec_gemini_e", "1.2.0", 1),
            1);
  EXPECT_EQ(toporoom_release_train_matches(train.c_str(), "0.2.0", "orbbec_gemini_e", "1.2.0", 1),
            0);
}
