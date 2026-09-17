#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"

namespace toporoom::domain {

// Room = 房间: closed wall ring + name + SpaceType + optional 室内净高.
class Room {
 public:
  Room(std::string id, std::vector<std::string> wall_ids, std::string name = {},
       SpaceType space_type = SpaceType::Interior,
       std::optional<LengthMm> clear_height = std::nullopt)
      : id_(std::move(id)),
        wall_ids_(std::move(wall_ids)),
        name_(std::move(name)),
        space_type_(space_type),
        clear_height_(clear_height) {}

  const std::string& id() const noexcept { return id_; }
  const std::vector<std::string>& wall_ids() const noexcept { return wall_ids_; }
  const std::string& name() const noexcept { return name_; }
  SpaceType space_type() const noexcept { return space_type_; }
  const std::optional<LengthMm>& clear_height() const noexcept { return clear_height_; }

  Room with_clear_height(LengthMm height) const {
    return Room(id_, wall_ids_, name_, space_type_, height);
  }

  Room with_name(std::string name) const {
    return Room(id_, wall_ids_, std::move(name), space_type_, clear_height_);
  }

  Room with_space_type(SpaceType space_type) const {
    return Room(id_, wall_ids_, name_, space_type, clear_height_);
  }

  Room with_attributes(std::string name, SpaceType space_type,
                       std::optional<LengthMm> clear_height) const {
    return Room(id_, wall_ids_, std::move(name), space_type, clear_height);
  }

 private:
  std::string id_;
  std::vector<std::string> wall_ids_;
  std::string name_;
  SpaceType space_type_ = SpaceType::Interior;
  std::optional<LengthMm> clear_height_;
};

}  // namespace toporoom::domain
