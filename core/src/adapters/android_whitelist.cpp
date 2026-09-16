#include "toporoom/adapters/android_whitelist.hpp"

#include <fstream>
#include <sstream>

#include <nlohmann/json.hpp>

namespace toporoom::adapters {
namespace {

HostPermissionFlags flags_from_json(const nlohmann::json& list) {
  HostPermissionFlags flags;
  for (const auto& item : list) {
    const auto name = item.get<std::string>();
    if (name == "BLUETOOTH_SCAN") flags.bluetooth_scan = true;
    if (name == "BLUETOOTH_CONNECT") flags.bluetooth_connect = true;
    if (name == "USB_HOST") flags.usb_host = true;
    if (name == "USB_DEVICE") flags.usb_device = true;
  }
  return flags;
}

}  // namespace

AndroidWhitelist AndroidWhitelist::from_json(const std::string& json_text) {
  const auto root = nlohmann::json::parse(json_text);
  AndroidWhitelist table;
  table.version_ = root.at("version").get<int>();
  if (root.contains("requiredPermissions")) {
    table.required_ = flags_from_json(root.at("requiredPermissions"));
  }
  for (const auto& row : root.at("entries")) {
    WhitelistEntry entry;
    entry.phone_model = row.at("phoneModel").get<std::string>();
    entry.android_api = row.at("androidApi").get<int>();
    entry.module_sku = row.at("moduleSku").get<std::string>();
    entry.firmware = row.at("firmware").get<std::string>();
    entry.hub_sku = row.at("hubSku").get<std::string>();
    entry.app_version = row.at("appVersion").get<std::string>();
    entry.usb_host = row.value("usbHost", false);
    entry.otg = row.value("otg", false);
    if (row.contains("permissions")) {
      entry.permissions = flags_from_json(row.at("permissions"));
    }
    table.entries_.push_back(std::move(entry));
  }
  return table;
}

AndroidWhitelist AndroidWhitelist::from_file(const std::string& path) {
  std::ifstream in(path);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return from_json(buffer.str());
}

bool AndroidWhitelist::allows(const WhitelistQuery& query) const {
  for (const auto& entry : entries_) {
    if (entry.phone_model == query.phone_model && entry.android_api == query.android_api &&
        entry.module_sku == query.module_sku && entry.firmware == query.firmware &&
        entry.hub_sku == query.hub_sku && entry.app_version == query.app_version) {
      return true;
    }
  }
  return false;
}

}  // namespace toporoom::adapters
