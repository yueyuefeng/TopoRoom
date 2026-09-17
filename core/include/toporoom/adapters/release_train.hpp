#pragma once

#include <string>
#include <vector>

namespace toporoom::adapters {

struct ReleaseTrainTrack {
  std::string id;
  std::string module_sku;
  std::string firmware;
  std::string note;
};

struct ReleaseTrain {
  int version = 0;
  std::string software_tag;
  std::string module_sku;
  std::string firmware;
  std::string hub_sku;
  std::string hub_firmware;
  std::string whitelist_file;
  int whitelist_version = 0;
  std::vector<ReleaseTrainTrack> tracks;
};

ReleaseTrain load_release_train_json(const std::string& json_text);
ReleaseTrain load_release_train_file(const std::string& path);

bool release_train_matches(const ReleaseTrain& train, const std::string& software_tag,
                           const std::string& module_sku, const std::string& firmware,
                           int whitelist_version, const std::string& hub_firmware = "");

}  // namespace toporoom::adapters
