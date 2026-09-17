#pragma once

#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/opening.hpp"
#include "toporoom/domain/point_mm.hpp"

namespace toporoom::domain {

struct WallProps {
  std::string id;
  PointMm start = PointMm::of(0, 0);
  PointMm end = PointMm::of(1, 0);
  LengthMm thickness = LengthMm::of(1);
  LengthMm height = LengthMm::of(1);
  WallKind kind = WallKind::Exterior;
  std::vector<Opening> openings;
};

class Wall {
 public:
  static Wall create(WallProps props);

  const std::string& id() const noexcept { return id_; }
  PointMm start() const noexcept { return start_; }
  PointMm end() const noexcept { return end_; }
  LengthMm thickness() const noexcept { return thickness_; }
  LengthMm height() const noexcept { return height_; }
  WallKind kind() const noexcept { return kind_; }
  const std::vector<Opening>& openings() const noexcept { return openings_; }
  LengthMm length_mm() const noexcept { return length_mm_; }

  Wall host_opening(const Opening& opening) const;
  Wall replace_opening(const Opening& opening) const;
  Wall without_opening(const std::string& opening_id) const;
  Wall with_height(LengthMm height) const;
  Wall with_kind(WallKind kind) const;
  Wall with_openings(std::vector<Opening> openings) const;
  Wall with_geometry(PointMm start, PointMm end) const;

  bool same_as(PointMm start, PointMm end, LengthMm thickness, LengthMm height,
               WallKind kind) const noexcept;

 private:
  Wall(WallProps props, std::vector<Opening> openings);
  WallProps snapshot() const;
  void assert_opening_fits(const Opening& opening) const;

  std::string id_;
  PointMm start_;
  PointMm end_;
  LengthMm thickness_;
  LengthMm height_;
  WallKind kind_;
  std::vector<Opening> openings_;
  LengthMm length_mm_;
};

}  // namespace toporoom::domain
