#include <gtest/gtest.h>

#include "toporoom/adapters/android_whitelist.hpp"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif

using toporoom::adapters::AndroidWhitelist;
using toporoom::adapters::WhitelistQuery;

namespace {

WhitelistQuery pixel8() {
  return {"Pixel 8", 34, "orbbec_gemini_e", "3460", "powered_hub_a", "0.1.0"};
}

}  // namespace

TEST(AndroidWhitelist, LoadsVersionedConfig) {
  const auto table = AndroidWhitelist::from_file(
      std::string(TOPOROOM_FIXTURE_DIR) + "/android-whitelist.v1.json");
  EXPECT_EQ(table.version(), 1);
  EXPECT_GE(table.entries().size(), 3u);
  EXPECT_FALSE(table.ios_external_depth_in_p0());
}

TEST(AndroidWhitelist, AllowsListedPhones) {
  const auto table = AndroidWhitelist::from_file(
      std::string(TOPOROOM_FIXTURE_DIR) + "/android-whitelist.v1.json");
  EXPECT_TRUE(table.allows(pixel8()));
  EXPECT_TRUE(table.allows(
      {"SM-S911B", 33, "orbbec_gemini_e", "3460", "powered_hub_a", "0.1.0"}));
  EXPECT_TRUE(table.allows(
      {"2201123G", 33, "orbbec_gemini_e", "3460", "powered_hub_a", "0.1.0"}));
}

TEST(AndroidWhitelist, DeniesUnknownAndIos) {
  const auto table = AndroidWhitelist::from_file(
      std::string(TOPOROOM_FIXTURE_DIR) + "/android-whitelist.v1.json");
  EXPECT_FALSE(table.allows(
      {"iPhone15,2", 17, "orbbec_gemini_e", "3460", "powered_hub_a", "0.1.0"}));
  EXPECT_FALSE(table.allows(
      {"Pixel 3", 34, "orbbec_gemini_e", "3460", "powered_hub_a", "0.1.0"}));
  EXPECT_FALSE(table.allows(
      {"Pixel 8", 34, "unknown_sku", "3460", "powered_hub_a", "0.1.0"}));
}

TEST(AndroidWhitelist, RequiresBtAndUsbPermissions) {
  const auto table = AndroidWhitelist::from_file(
      std::string(TOPOROOM_FIXTURE_DIR) + "/android-whitelist.v1.json");
  const auto flags = table.required_permissions();
  EXPECT_TRUE(flags.bluetooth_scan);
  EXPECT_TRUE(flags.bluetooth_connect);
  EXPECT_TRUE(flags.usb_host);
  EXPECT_TRUE(flags.usb_device);
}
