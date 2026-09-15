#pragma once

#include <string>
#include <vector>

namespace toporoom::domain {

class Room {
 public:
  Room(std::string id, std::vector<std::string> wall_ids)
      : id_(std::move(id)), wall_ids_(std::move(wall_ids)) {}

  const std::string& id() const noexcept { return id_; }
  const std::vector<std::string>& wall_ids() const noexcept { return wall_ids_; }

 private:
  std::string id_;
  std::vector<std::string> wall_ids_;
};

}  // namespace toporoom::domain
