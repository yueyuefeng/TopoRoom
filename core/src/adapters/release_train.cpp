#include "toporoom/adapters/release_train.hpp"

#include <fstream>
#include <sstream>

#include <nlohmann/json.hpp>

namespace toporoom::adapters {

ReleaseTrain load_release_train_json(const std::string& json_text) {
  const auto root = nlohmann::json::parse(json_text);
  ReleaseTrain train;
  train.version = root.at("version").get<int>();
  train.software_tag = root.at("softwareTag").get<std::string>();
  train.module_sku = root.at("moduleSku").get<std::string>();
  train.firmware = root.at("firmware").get<std::string>();
  train.whitelist_file = root.at("whitelistFile").get<std::string>();
  train.whitelist_version = root.at("whitelistVersion").get<int>();
  return train;
}

ReleaseTrain load_release_train_file(const std::string& path) {
  std::ifstream in(path);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return load_release_train_json(buffer.str());
}

bool release_train_matches(const ReleaseTrain& train, const std::string& software_tag,
                           const std::string& module_sku, const std::string& firmware,
                           int whitelist_version) {
  return train.software_tag == software_tag && train.module_sku == module_sku &&
         train.firmware == firmware && train.whitelist_version == whitelist_version;
}

}  // namespace toporoom::adapters
