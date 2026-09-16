#pragma once

#include <string>
#include <vector>

namespace toporoom::adapters {

struct HostPermissionFlags {
  bool bluetooth_scan = false;
  bool bluetooth_connect = false;
  bool usb_host = false;
  bool usb_device = false;
};

struct WhitelistQuery {
  std::string phone_model;
  int android_api = 0;
  std::string module_sku;
  std::string firmware;
  std::string hub_sku;
  std::string app_version;
};

struct WhitelistEntry {
  std::string phone_model;
  int android_api = 0;
  std::string module_sku;
  std::string firmware;
  std::string hub_sku;
  std::string app_version;
  bool usb_host = false;
  bool otg = false;
  HostPermissionFlags permissions;
};

class AndroidWhitelist {
 public:
  static AndroidWhitelist from_json(const std::string& json_text);
  static AndroidWhitelist from_file(const std::string& path);

  int version() const noexcept { return version_; }
  bool ios_external_depth_in_p0() const noexcept { return false; }
  bool allows(const WhitelistQuery& query) const;
  HostPermissionFlags required_permissions() const noexcept { return required_; }
  const std::vector<WhitelistEntry>& entries() const noexcept { return entries_; }

 private:
  int version_ = 0;
  std::vector<WhitelistEntry> entries_;
  HostPermissionFlags required_{};
};

}  // namespace toporoom::adapters
