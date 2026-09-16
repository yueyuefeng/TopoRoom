#pragma once

#include <string>
#include <vector>

#include "toporoom/ports/p1_status.hpp"

namespace toporoom::ports {

// FR-105 placeholder: points + polylines. No circuits, no DXF layer in P0.
struct MepPoint {
  std::string id;
  double x_mm = 0;
  double y_mm = 0;
  std::string kind;
};

struct MepPolyline {
  std::string id;
  std::vector<std::string> point_ids;
};

class MepPort {
 public:
  virtual ~MepPort() = default;
  virtual P1Status add_point(const MepPoint& point) = 0;
  virtual P1Status add_polyline(const MepPolyline& polyline) = 0;
};

}  // namespace toporoom::ports
