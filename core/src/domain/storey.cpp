#include "toporoom/domain/storey.hpp"

#include <cmath>
#include <map>
#include <set>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/point_mm.hpp"

namespace toporoom::domain {

Storey::Storey(StoreyProps props)
    : id_(std::move(props.id)),
      elevation_(props.elevation),
      height_(props.height),
      walls_(std::move(props.walls)),
      rooms_(std::move(props.rooms)) {}

Storey Storey::create(StoreyProps props) {
  if (props.height.value() <= 0) {
    throw DomainError("Storey height must be positive", "INVALID_STOREY");
  }
  return Storey(std::move(props));
}

Storey Storey::add_wall(const Wall& wall) const {
  for (const auto& existing : walls_) {
    if (existing.id() == wall.id()) {
      throw DomainError("Wall " + wall.id() + " already exists", "DUPLICATE_WALL");
    }
  }
  StoreyProps props;
  props.id = id_;
  props.elevation = elevation_;
  props.height = height_;
  props.walls = walls_;
  props.walls.push_back(wall);
  props.rooms = rooms_;
  return Storey(std::move(props));
}

const Wall& Storey::wall_by_id(const std::string& wall_id) const {
  for (const auto& wall : walls_) {
    if (wall.id() == wall_id) return wall;
  }
  throw DomainError("Wall " + wall_id + " not found", "WALL_NOT_FOUND");
}

Storey Storey::host_opening(const std::string& wall_id, const Opening& opening) const {
  return replace_wall(wall_by_id(wall_id).host_opening(opening));
}

Storey Storey::replace_wall(const Wall& wall) const {
  StoreyProps props;
  props.id = id_;
  props.elevation = elevation_;
  props.height = height_;
  props.rooms = rooms_;
  bool found = false;
  for (const auto& existing : walls_) {
    if (existing.id() == wall.id()) {
      props.walls.push_back(wall);
      found = true;
    } else {
      props.walls.push_back(existing);
    }
  }
  if (!found) {
    throw DomainError("Wall " + wall.id() + " not found", "WALL_NOT_FOUND");
  }
  return Storey(std::move(props));
}

Storey Storey::with_height(LengthMm height) const {
  StoreyProps props;
  props.id = id_;
  props.elevation = elevation_;
  props.height = height;
  props.walls = walls_;
  props.rooms = rooms_;
  return Storey::create(std::move(props));
}

Storey Storey::close_room(const std::string& id,
                          const std::vector<std::string>& wall_ids) const {
  for (const auto& room : rooms_) {
    if (room.id() == id) {
      throw DomainError("Room " + id + " already exists", "DUPLICATE_ROOM");
    }
  }
  assert_closed_loop(wall_ids);
  StoreyProps props;
  props.id = id_;
  props.elevation = elevation_;
  props.height = height_;
  props.walls = walls_;
  props.rooms = rooms_;
  props.rooms.emplace_back(id, wall_ids);
  return Storey(std::move(props));
}

void Storey::assert_closed_loop(const std::vector<std::string>& wall_ids) const {
  if (wall_ids.size() < 3) {
    throw DomainError("A closed room needs at least three walls", "ROOM_NOT_CLOSED");
  }
  std::set<std::string> unique(wall_ids.begin(), wall_ids.end());
  if (unique.size() != wall_ids.size()) {
    throw DomainError("Room walls must be unique", "ROOM_NOT_CLOSED");
  }
  std::vector<Wall> walls;
  walls.reserve(wall_ids.size());
  for (const auto& wall_id : wall_ids) {
    walls.push_back(wall_by_id(wall_id));
  }
  for (std::size_t i = 0; i < walls.size(); ++i) {
    const Wall& current = walls[i];
    const Wall& next = walls[(i + 1) % walls.size()];
    const bool shares =
        current.end().equals(next.start()) || current.end().equals(next.end()) ||
        current.start().equals(next.start()) || current.start().equals(next.end());
    if (!shares) {
      throw DomainError(
          "Walls " + current.id() + " and " + next.id() + " do not share an endpoint",
          "ROOM_NOT_CLOSED");
    }
  }
  std::map<std::pair<long long, long long>, int> endpoints;
  auto key = [](const PointMm& p) {
    return std::pair<long long, long long>{
        static_cast<long long>(std::llround(p.x() * 1000)),
        static_cast<long long>(std::llround(p.y() * 1000))};
  };
  for (const auto& wall : walls) {
    endpoints[key(wall.start())] += 1;
    endpoints[key(wall.end())] += 1;
  }
  for (const auto& [_, degree] : endpoints) {
    (void)_;
    if (degree != 2) {
      throw DomainError("Room walls must form a single closed loop", "ROOM_NOT_CLOSED");
    }
  }
}

}  // namespace toporoom::domain
