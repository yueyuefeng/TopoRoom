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
  train.hub_sku = root.value("hubSku", std::string{});
  train.hub_firmware = root.value("hubFirmware", std::string{});
  train.whitelist_file = root.at("whitelistFile").get<std::string>();
  train.whitelist_version = root.at("whitelistVersion").get<int>();
  if (root.contains("tracks")) {
    for (const auto& row : root.at("tracks")) {
      ReleaseTrainTrack track;
      track.id = row.value("id", std::string{});
      track.module_sku = row.at("moduleSku").get<std::string>();
      track.firmware = row.at("firmware").get<std::string>();
      track.note = row.value("note", std::string{});
      train.tracks.push_back(std::move(track));
    }
  }
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
                           int whitelist_version, const std::string& hub_firmware) {
  if (train.software_tag != software_tag || train.whitelist_version != whitelist_version) {
    return false;
  }
  if (!hub_firmware.empty() && !train.hub_firmware.empty() &&
      train.hub_firmware != hub_firmware) {
    return false;
  }
  auto sku_fw_ok = [&](const std::string& sku, const std::string& fw) {
    return sku == module_sku && fw == firmware;
  };
  if (sku_fw_ok(train.module_sku, train.firmware)) return true;
  for (const auto& track : train.tracks) {
    if (sku_fw_ok(track.module_sku, track.firmware)) return true;
  }
  return false;
}

}  // namespace toporoom::adapters
