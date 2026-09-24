#pragma once

#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include "toporoom/app/param_gathering_fsm.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

namespace toporoom::app {

struct AddWallDraft {
  std::string type = "AddWall";
  double start_x = 0;
  double start_y = 0;
  double end_x = 0;
  double end_y = 0;
  double thickness_mm = 0;
};

class WallDrawTool {
 public:
  static constexpr const char* kId = "WallDrawTool";

  ParamGatheringFSM create_fsm() const {
    std::vector<ToolStep> steps;
    steps.push_back(ToolStep{
        "start", [](const std::string& raw, auto& out) { out["start"] = raw; }});
    steps.push_back(
        ToolStep{"end", [](const std::string& raw, auto& out) { out["end"] = raw; }});
    steps.push_back(ToolStep{
        "thickness", [](const std::string& raw, auto& out) { out["thickness"] = raw; }});
    return ParamGatheringFSM(kId, std::move(steps));
  }

  static AddWallDraft complete(const std::unordered_map<std::string, std::string>& params) {
    auto require = [&](const char* key) {
      auto it = params.find(key);
      if (it == params.end()) {
        throw std::runtime_error(std::string("missing ") + key);
      }
      return it->second;
    };
    double sx = 0, sy = 0, ex = 0, ey = 0, thickness = 0;
    parse_point(require("start"), sx, sy);
    parse_point(require("end"), ex, ey);
    thickness = std::stod(require("thickness"));
    domain::PointMm::of(sx, sy);
    domain::PointMm::of(ex, ey);
    domain::LengthMm::of(thickness);
    return AddWallDraft{"AddWall", sx, sy, ex, ey, thickness};
  }

  static void parse_point(const std::string& raw, double& x, double& y) {
    const auto comma = raw.find(',');
    if (comma == std::string::npos) {
      throw std::runtime_error("expected PointMm as 'x,y'");
    }
    x = std::stod(raw.substr(0, comma));
    y = std::stod(raw.substr(comma + 1));
  }
};

struct PolylineSeg {
  std::string id;
  double x0 = 0;
  double y0 = 0;
  double x1 = 0;
  double y1 = 0;
};

struct PolylineWallsResult {
  std::vector<PolylineSeg> walls;
  bool closed = false;
};

/* Floor outline → axis-agnostic wall segments. Near-closed last≈first snaps. */
PolylineWallsResult walls_from_polyline(const std::vector<domain::PointMm>& pts,
                                        bool close_loop, const std::string& prefix,
                                        int serial_start, double min_len_mm = 200.0,
                                        double close_snap_mm = 400.0);

}  // namespace toporoom::app
