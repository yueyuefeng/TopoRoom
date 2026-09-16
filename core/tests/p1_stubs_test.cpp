#include <filesystem>
#include <string>
#include <type_traits>
#include <vector>

#include <gtest/gtest.h>

#include "toporoom/adapters/p1_stubs.hpp"
#include "toporoom/c_api/toporoom.h"
#include "toporoom/ports/cloud_sync_port.hpp"
#include "toporoom/ports/furnishing_port.hpp"
#include "toporoom/ports/mep_port.hpp"
#include "toporoom/ports/p1_status.hpp"
#include "toporoom/ports/takeoff_quote_port.hpp"

namespace fs = std::filesystem;

using toporoom::adapters::NotImplementedCloudSyncAdapter;
using toporoom::adapters::NotImplementedFurnishingAdapter;
using toporoom::adapters::NotImplementedMepAdapter;
using toporoom::adapters::NotImplementedQuoteAdapter;
using toporoom::ports::kNotInP0;

TEST(OutOfScopeP1, PortsAreAbstractAndNotP0Gates) {
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::MepPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::FurnishingLibraryPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::CloudSyncPort>);
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::TakeoffQuotePort>);
}

TEST(OutOfScopeP1, StubsReturnNotInP0) {
  NotImplementedMepAdapter mep;
  const auto point = mep.add_point({"p1", 0, 0, "outlet"});
  EXPECT_FALSE(point.ok);
  EXPECT_EQ(point.code, kNotInP0);
  EXPECT_NE(point.message.find("FR-013"), std::string::npos);
  EXPECT_EQ(mep.add_polyline({"run_1", {"p1"}}).code, kNotInP0);

  NotImplementedFurnishingAdapter soft;
  std::vector<toporoom::ports::FurnishingItem> catalog;
  const auto listed = soft.list_catalog(catalog);
  EXPECT_FALSE(listed.ok);
  EXPECT_EQ(listed.code, kNotInP0);
  EXPECT_TRUE(catalog.empty());
  EXPECT_EQ(soft.place("doc_1", "sofa_sku").code, kNotInP0);

  NotImplementedCloudSyncAdapter cloud;
  EXPECT_EQ(cloud.push_document("doc_1").code, kNotInP0);
  EXPECT_EQ(cloud.pull_document("doc_1").code, kNotInP0);

  NotImplementedQuoteAdapter quote;
  std::string json = "should-clear";
  const auto quoted = quote.quote_document("doc_1", json);
  EXPECT_FALSE(quoted.ok);
  EXPECT_EQ(quoted.code, kNotInP0);
  EXPECT_TRUE(json.empty());
}

TEST(OutOfScopeP1, GuideAndExportSucceedWithoutP1PortsRegistered) {
  const auto tmp = fs::temp_directory_path() / "toporoom-p0-without-p1";
  fs::remove_all(tmp);
  fs::create_directories(tmp);

  TopoRoomDocument* doc = toporoom_document_create("doc_p0");
  ASSERT_NE(doc, nullptr);
  TopoRoomGuide* guide = toporoom_guide_create();
  ASSERT_NE(guide, nullptr);

  char err[256] = {};
  ASSERT_EQ(toporoom_debug_fake_one_room(doc, guide, tmp.string().c_str(), err, sizeof(err)),
            0)
      << err;
  EXPECT_EQ(toporoom_guide_can_export(guide), 1);
  EXPECT_TRUE(fs::exists(tmp / "room.glb"));

  char* scene = toporoom_document_to_sceneir_json(doc);
  ASSERT_NE(scene, nullptr);
  const std::string text(scene);
  EXPECT_EQ(text.find("mep"), std::string::npos);
  EXPECT_EQ(text.find("furnishing"), std::string::npos);
  EXPECT_EQ(text.find("cloudSync"), std::string::npos);
  EXPECT_EQ(text.find("quote"), std::string::npos);
  toporoom_string_free(scene);

  toporoom_guide_destroy(guide);
  toporoom_document_destroy(doc);
  fs::remove_all(tmp);
}
