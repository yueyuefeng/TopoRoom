#pragma once

#include <string>
#include <vector>

#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/opening.hpp"
#include "toporoom/domain/room.hpp"
#include "toporoom/domain/wall.hpp"

namespace toporoom::domain {

struct StoreyProps {
  std::string id;
  LengthMm elevation = LengthMm::zero();
  LengthMm height = LengthMm::of(2800);
  std::vector<Wall> walls;
  std::vector<Room> rooms;
};

class Storey {
 public:
  static Storey create(StoreyProps props);

  const std::string& id() const noexcept { return id_; }
  LengthMm elevation() const noexcept { return elevation_; }
  LengthMm height() const noexcept { return height_; }
  const std::vector<Wall>& walls() const noexcept { return walls_; }
  const std::vector<Room>& rooms() const noexcept { return rooms_; }

  Storey add_wall(const Wall& wall) const;
  const Wall& wall_by_id(const std::string& wall_id) const;
  Storey host_opening(const std::string& wall_id, const Opening& opening) const;
  Storey replace_wall(const Wall& wall) const;
  Storey with_height(LengthMm height) const;
  Storey close_room(const std::string& id, const std::vector<std::string>& wall_ids) const;

 private:
  explicit Storey(StoreyProps props);
  void assert_closed_loop(const std::vector<std::string>& wall_ids) const;

  std::string id_;
  LengthMm elevation_;
  LengthMm height_;
  std::vector<Wall> walls_;
  std::vector<Room> rooms_;
};

}  // namespace toporoom::domain
