#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/hosted_component.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/opening.hpp"
#include "toporoom/domain/room.hpp"
#include "toporoom/domain/wall.hpp"

namespace toporoom::domain {

struct StoreyProps {
  std::string id;
  LengthMm elevation = LengthMm::zero();
  // Storey.height = 层高 (structure-to-structure). Never 室内净高 (I4).
  LengthMm height = LengthMm::of(2800);
  std::vector<Wall> walls;
  std::vector<Room> rooms;
  std::vector<HostedComponent> hosted_components;
};

class Storey {
 public:
  static Storey create(StoreyProps props);

  const std::string& id() const noexcept { return id_; }
  LengthMm elevation() const noexcept { return elevation_; }
  LengthMm height() const noexcept { return height_; }
  const std::vector<Wall>& walls() const noexcept { return walls_; }
  const std::vector<Room>& rooms() const noexcept { return rooms_; }
  const std::vector<HostedComponent>& hosted_components() const noexcept {
    return hosted_components_;
  }

  Storey add_wall(const Wall& wall) const;
  const Wall& wall_by_id(const std::string& wall_id) const;
  Storey host_opening(const std::string& wall_id, const Opening& opening) const;
  Storey replace_wall(const Wall& wall) const;
  // O1 / D10: default walls whose height matched the previous 层高 follow; others stay.
  Storey with_height(LengthMm height, bool follow_matching_walls = true) const;
  Storey close_room(const Room& room) const;
  Storey close_room(const std::string& id, const std::vector<std::string>& wall_ids) const;
  Storey replace_room(const Room& room) const;
  Storey place_hosted_component(HostedComponent component) const;

 private:
  explicit Storey(StoreyProps props);
  StoreyProps snapshot() const;
  void assert_closed_loop(const std::vector<std::string>& wall_ids) const;

  std::string id_;
  LengthMm elevation_;
  LengthMm height_;
  std::vector<Wall> walls_;
  std::vector<Room> rooms_;
  std::vector<HostedComponent> hosted_components_;
};

}  // namespace toporoom::domain
