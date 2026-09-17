#include <gtest/gtest.h>

#include "toporoom/adapters/release_train.hpp"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif

using toporoom::adapters::load_release_train_file;
using toporoom::adapters::release_train_matches;

TEST(ReleaseTrain, MapsSoftwareTagToModuleAndWhitelist) {
  const auto train = load_release_train_file(std::string(TOPOROOM_FIXTURE_DIR) +
                                             "/release-train.v1.json");
  EXPECT_EQ(train.version, 1);
  EXPECT_EQ(train.software_tag, "0.1.0");
  EXPECT_EQ(train.module_sku, "orbbec_gemini_e");
  EXPECT_EQ(train.firmware, "3460");
  EXPECT_EQ(train.hub_sku, "toporoom_hub_c3");
  EXPECT_EQ(train.hub_firmware, "0.1.0");
  EXPECT_EQ(train.whitelist_file, "android-whitelist.v1.json");
  EXPECT_EQ(train.whitelist_version, 1);
  EXPECT_TRUE(release_train_matches(train, "0.1.0", "orbbec_gemini_e", "3460", 1, "0.1.0"));
  EXPECT_FALSE(release_train_matches(train, "0.2.0", "orbbec_gemini_e", "3460", 1, "0.1.0"));
  EXPECT_FALSE(release_train_matches(train, "0.1.0", "orbbec_gemini_e", "3460", 1, "9.9.9"));
}
