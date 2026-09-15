#include <string>

#include <gtest/gtest.h>

#include "toporoom/c_api/toporoom.h"

TEST(CApi, VersionAndDocumentRoundTrip) {
  EXPECT_STREQ(toporoom_version(), "0.1.0");
  TopoRoomDocument* doc = toporoom_document_create("doc_c");
  ASSERT_NE(doc, nullptr);
  char err[256] = {};
  const int rc = toporoom_document_add_wall(doc, "storey_1", "wall_s", 0, 0, 4000, 0, 200,
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
