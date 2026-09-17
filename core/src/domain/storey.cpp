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
      rooms_(std::move(props.rooms)),
      hosted_components_(std::move(props.hosted_components)) {}

StoreyProps Storey::snapshot() const {
  StoreyProps props;
  props.id = id_;
  props.elevation = elevation_;
  props.height = height_;
  props.walls = walls_;
  props.rooms = rooms_;
  props.hosted_components = hosted_components_;
  return props;
}

Storey Storey::create(StoreyProps props) {
  if (props.height.value() <= 0) {
    throw DomainError("Storey height (层高) must be positive", "INVALID_STOREY");
  }
  return Storey(std::move(props));
}

Storey Storey::add_wall(const Wall& wall) const {
  for (const auto& existing : walls_) {
    if (existing.id() == wall.id()) {
      throw DomainError("Wall " + wall.id() + " already exists", "DUPLICATE_WALL");
    }
  }
  auto props = snapshot();
  props.walls.push_back(wall);
  return Storey(std::move(props));
}

const Wall& Storey::wall_by_id(const std::string& wall_id) const {
  for (const auto& wall : walls_) {
    if (wall.id() == wall_id) return wall;
  }
  throw DomainError("Wall " + wall_id + " not found", "WALL_NOT_FOUND");
}

bool Storey::has_wall(const std::string& wall_id) const noexcept {
  for (const auto& wall : walls_) {
    if (wall.id() == wall_id) return true;
  }
  return false;
}

Storey Storey::host_opening(const std::string& wall_id, const Opening& opening) const {
  return replace_wall(wall_by_id(wall_id).host_opening(opening));
}

Storey Storey::replace_wall(const Wall& wall) const {
  auto props = snapshot();
  props.walls.clear();
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

Storey Storey::remove_wall(const std::string& wall_id) const {
  wall_by_id(wall_id);
  auto props = snapshot();
  props.walls.clear();
  for (const auto& wall : walls_) {
    if (wall.id() != wall_id) props.walls.push_back(wall);
  }
  std::vector<Room> rooms;
  for (const auto& room : rooms_) {
    bool uses_wall = false;
    for (const auto& id : room.wall_ids()) {
      if (id == wall_id) {
        uses_wall = true;
        break;
      }
    }
    if (!uses_wall) rooms.push_back(room);
  }
  props.rooms = std::move(rooms);
  std::vector<HostedComponent> hosted;
  for (const auto& component : hosted_components_) {
    if (component.host_wall_id && *component.host_wall_id == wall_id) continue;
    hosted.push_back(component);
  }
  props.hosted_components = std::move(hosted);
  return Storey(std::move(props));
}

Storey Storey::remove_opening(const std::string& opening_id) const {
  for (const auto& wall : walls_) {
    for (const auto& opening : wall.openings()) {
      if (opening.id() != opening_id) continue;
      return replace_wall(wall.without_opening(opening_id));
    }
  }
  throw DomainError("Opening " + opening_id + " not found", "OPENING_NOT_FOUND");
}

Storey Storey::with_height(LengthMm height, bool follow_matching_walls) const {
  auto props = snapshot();
  props.height = height;
  if (follow_matching_walls) {
    props.walls.clear();
    for (const auto& wall : walls_) {
      if (wall.height().value() == height_.value()) {
        props.walls.push_back(wall.with_height(height));
      } else {
        props.walls.push_back(wall);
      }
    }
  }
  return Storey::create(std::move(props));
}

Storey Storey::close_room(const Room& room) const {
  for (const auto& existing : rooms_) {
    if (existing.id() == room.id()) {
      throw DomainError("Room " + room.id() + " already exists", "DUPLICATE_ROOM");
    }
  }
  assert_closed_loop(room.wall_ids());
  auto props = snapshot();
  props.rooms.push_back(room);
  return Storey(std::move(props));
}

Storey Storey::close_room(const std::string& id,
                          const std::vector<std::string>& wall_ids) const {
  return close_room(Room(id, wall_ids));
}

Storey Storey::replace_room(const Room& room) const {
  auto props = snapshot();
  props.rooms.clear();
  bool found = false;
  for (const auto& existing : rooms_) {
    if (existing.id() == room.id()) {
      props.rooms.push_back(room);
      found = true;
    } else {
      props.rooms.push_back(existing);
    }
  }
  if (!found) {
    throw DomainError("Room " + room.id() + " not found", "ROOM_NOT_FOUND");
  }
  return Storey(std::move(props));
}

Storey Storey::place_hosted_component(HostedComponent component) const {
  for (const auto& existing : hosted_components_) {
    if (existing.id == component.id) {
      throw DomainError("HostedComponent " + component.id + " already exists",
                        "DUPLICATE_HOSTED");
    }
  }
  if (component.host_wall_id) {
    wall_by_id(*component.host_wall_id);
  }
  auto props = snapshot();
  props.hosted_components.push_back(std::move(component));
  return Storey(std::move(props));
}

Storey Storey::replace_hosted_component(HostedComponent component) const {
  if (component.host_wall_id) {
    wall_by_id(*component.host_wall_id);
  }
  auto props = snapshot();
  props.hosted_components.clear();
  bool found = false;
  for (const auto& existing : hosted_components_) {
    if (existing.id == component.id) {
      props.hosted_components.push_back(component);
      found = true;
    } else {
      props.hosted_components.push_back(existing);
    }
  }
  if (!found) {
    throw DomainError("HostedComponent " + component.id + " not found",
                      "HOSTED_NOT_FOUND");
  }
  return Storey(std::move(props));
}

Storey Storey::remove_hosted_component(const std::string& component_id) const {
  auto props = snapshot();
  props.hosted_components.clear();
  bool found = false;
  for (const auto& existing : hosted_components_) {
    if (existing.id == component_id) {
      found = true;
      continue;
    }
    props.hosted_components.push_back(existing);
  }
  if (!found) {
    throw DomainError("HostedComponent " + component_id + " not found",
                      "HOSTED_NOT_FOUND");
  }
  return Storey(std::move(props));
}

const HostedComponent* Storey::hosted_by_id(const std::string& component_id) const noexcept {
  for (const auto& existing : hosted_components_) {
    if (existing.id == component_id) return &existing;
  }
  return nullptr;
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
