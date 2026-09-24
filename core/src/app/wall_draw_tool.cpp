#include "toporoom/app/wall_draw_tool.hpp"

#include <cmath>
#include <utility>

namespace toporoom::app {

int wall_draw_tool_module() { return 0; }

PolylineWallsResult walls_from_polyline(const std::vector<domain::PointMm>& pts,
                                        bool close_loop, const std::string& prefix,
                                        int serial_start, double min_len_mm,
                                        double close_snap_mm) {
  PolylineWallsResult out;
  if (pts.size() < 2) {
    return out;
  }
  const double min_len = min_len_mm > 0.0 ? min_len_mm : 200.0;
  const double snap = close_snap_mm > 0.0 ? close_snap_mm : 400.0;
  const std::string id_prefix = prefix.empty() ? std::string("wall_a") : prefix;
  int serial = serial_start > 0 ? serial_start : 1;

  std::vector<domain::PointMm> ring = pts;
  if (close_loop && ring.size() >= 3 && ring.back().distance_to(ring.front()) < snap) {
    ring.pop_back();
  }
  if (ring.size() < 2) {
    return out;
  }

  auto push_seg = [&](const domain::PointMm& a, const domain::PointMm& b) {
    if (a.distance_to(b) < min_len) {
      return;
    }
    PolylineSeg seg;
    seg.id = id_prefix + std::to_string(serial);
    seg.x0 = a.x();
    seg.y0 = a.y();
    seg.x1 = b.x();
    seg.y1 = b.y();
    out.walls.push_back(std::move(seg));
    serial += 1;
  };

  for (std::size_t i = 0; i + 1 < ring.size(); ++i) {
    push_seg(ring[i], ring[i + 1]);
  }
  if (close_loop && ring.size() >= 3) {
    const double gap = ring.back().distance_to(ring.front());
    if (gap >= min_len) {
      push_seg(ring.back(), ring.front());
      out.closed = true;
    } else if (gap < snap && !out.walls.empty()) {
      out.closed = true;
    }
  }
  return out;
}

}  // namespace toporoom::app
