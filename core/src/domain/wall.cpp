#include "toporoom/domain/wall.hpp"

#include "toporoom/domain/error.hpp"

namespace toporoom::domain {

Wall::Wall(WallProps props, std::vector<Opening> openings)
    : id_(std::move(props.id)),
      start_(props.start),
      end_(props.end),
      thickness_(props.thickness),
      height_(props.height),
      kind_(props.kind),
      openings_(std::move(openings)),
      length_mm_(LengthMm::of(props.start.distance_to(props.end))) {}

WallProps Wall::snapshot() const {
  WallProps props;
  props.id = id_;
  props.start = start_;
  props.end = end_;
  props.thickness = thickness_;
  props.height = height_;
  props.kind = kind_;
  props.openings = openings_;
  return props;
}

Wall Wall::create(WallProps props) {
  const double length = props.start.distance_to(props.end);
  if (length <= 0) {
    throw DomainError("Wall length must be positive", "INVALID_WALL");
  }
  if (props.thickness.value() <= 0) {
    throw DomainError("Wall thickness must be positive", "INVALID_WALL");
  }
  if (props.height.value() <= 0) {
    throw DomainError("Wall height must be positive", "INVALID_WALL");
  }
  auto openings = std::move(props.openings);
  Wall wall(std::move(props), openings);
  for (const auto& opening : wall.openings_) {
    wall.assert_opening_fits(opening);
  }
  return wall;
}

Wall Wall::host_opening(const Opening& opening) const {
  assert_opening_fits(opening);
  for (const auto& existing : openings_) {
    if (existing.id() == opening.id()) {
      throw DomainError("Opening " + opening.id() + " already hosted on wall " + id_,
                        "DUPLICATE_OPENING");
    }
  }
  auto props = snapshot();
  props.openings.push_back(opening);
  auto openings = props.openings;
  return Wall(std::move(props), std::move(openings));
}

Wall Wall::replace_opening(const Opening& opening) const {
  auto props = snapshot();
  bool found = false;
  for (auto& candidate : props.openings) {
    if (candidate.id() == opening.id()) {
      candidate = opening;
      found = true;
      break;
    }
  }
  if (!found) {
    throw DomainError("Opening " + opening.id() + " is not hosted on wall " + id_,
                      "OPENING_NOT_FOUND");
  }
  return Wall::create(std::move(props));
}

Wall Wall::without_opening(const std::string& opening_id) const {
  auto props = snapshot();
  std::vector<Opening> kept;
  kept.reserve(props.openings.size());
  bool found = false;
  for (const auto& opening : props.openings) {
    if (opening.id() == opening_id) {
      found = true;
      continue;
    }
    kept.push_back(opening);
  }
  if (!found) {
    throw DomainError("Opening " + opening_id + " is not hosted on wall " + id_,
                      "OPENING_NOT_FOUND");
  }
  props.openings = std::move(kept);
  return Wall::create(std::move(props));
}

Wall Wall::with_height(LengthMm height) const {
  auto props = snapshot();
  props.height = height;
  return Wall::create(std::move(props));
}

Wall Wall::with_geometry(PointMm start, PointMm end) const {
  auto props = snapshot();
  props.start = start;
  props.end = end;
  return Wall::create(std::move(props));
}

bool Wall::same_as(PointMm start, PointMm end, LengthMm thickness, LengthMm height,
                   WallKind kind) const noexcept {
  return start_.equals(start) && end_.equals(end) &&
         thickness_.value() == thickness.value() && height_.value() == height.value() &&
         kind_ == kind;
}

void Wall::assert_opening_fits(const Opening& opening) const {
  if (opening.offset_along_wall().value() < 0) {
    throw DomainError("Opening offset must not be negative", "OPENING_OUT_OF_BOUNDS");
  }
  if (opening.occupies_until_mm() > length_mm_.value() + 1e-6) {
    throw DomainError("Opening extends past the host wall length",
                      "OPENING_OUT_OF_BOUNDS");
  }
  if (opening.sill_height().value() + opening.height().value() >
      height_.value() + 1e-6) {
    throw DomainError("Opening is taller than the host wall",
                      "OPENING_OUT_OF_BOUNDS");
  }
}

}  // namespace toporoom::domain
