#include <filesystem>
#include <fstream>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/c_api/toporoom.h"

namespace fs = std::filesystem;

TEST(GuidedCaptureLoop, FakeOneRoomExportsAndGuideReady) {
  const auto tmp = fs::temp_directory_path() / "toporoom-fake-one-room";
  fs::remove_all(tmp);
  fs::create_directories(tmp);

  TopoRoomDocument* doc = toporoom_document_create("doc_fake");
  ASSERT_NE(doc, nullptr);
  TopoRoomGuide* guide = toporoom_guide_create();
  ASSERT_NE(guide, nullptr);
  EXPECT_STREQ(toporoom_guide_phase(guide), "host_check");

  char err[256] = {};
  const int rc =
      toporoom_debug_fake_one_room(doc, guide, tmp.string().c_str(), err, sizeof(err));
  EXPECT_EQ(rc, 0) << err;
  EXPECT_EQ(toporoom_guide_can_export(guide), 1);
  EXPECT_STREQ(toporoom_guide_phase(guide), "export");
  EXPECT_STREQ(toporoom_guide_blocking_reason(guide), "");

  EXPECT_TRUE(fs::exists(tmp / "room.glb"));
  EXPECT_TRUE(fs::file_size(tmp / "room.glb") > 12u);
  EXPECT_TRUE(fs::exists(tmp / "room.dxf"));
  EXPECT_TRUE(fs::exists(tmp / "room.pdf"));

  char* json = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(json, nullptr);
  const std::string text(json);
  EXPECT_NE(text.find("wall_s"), std::string::npos);
  EXPECT_NE(text.find("op_door"), std::string::npos);
  EXPECT_NE(text.find("\"source\": \"laser\""), std::string::npos);
  toporoom_string_free(json);

  toporoom_guide_destroy(guide);
  toporoom_document_destroy(doc);
  fs::remove_all(tmp);
}

TEST(GuidedCaptureLoop, RejectsSecondFill) {
  TopoRoomDocument* doc = toporoom_document_create("doc_twice");
  ASSERT_NE(doc, nullptr);
  char err[256] = {};
  ASSERT_EQ(toporoom_debug_fake_one_room(doc, nullptr, nullptr, err, sizeof(err)), 0)
      << err;
  EXPECT_NE(toporoom_debug_fake_one_room(doc, nullptr, nullptr, err, sizeof(err)), 0);
  toporoom_document_destroy(doc);
}
