#pragma once

#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/ports/floor_plan_vision_port.hpp"

namespace toporoom::adapters {

// Axis-aligned wall centerline in millimetres.
struct RasterSeg {
  double x0 = 0;
  double y0 = 0;
  double x1 = 0;
  double y1 = 0;
  double thickness_mm = 200;
  domain::WallKind kind = domain::WallKind::Masonry;
  std::string id;
};

struct BayBump {
  double x0 = 0;
  double y0 = 0;
  double x1 = 0;
  double y1 = 0;
  char ori = 'H';  // front opening orientation
};

// Merge collinear fragments of the same WallKind. Adjacent or gapped segments
// whose gap is ≤ gap_merge_mm are joined (openings then sit on the long wall).
std::vector<RasterSeg> merge_collinear_segments(const std::vector<RasterSeg>& segs,
                                                double snap_mm, double gap_merge_mm);

// Cluster nearby unique X and Y coordinates and rewrite endpoints.
std::vector<RasterSeg> snap_endpoints(const std::vector<RasterSeg>& segs, double snap_mm);

// Infer short missing exterior edges so degree-1 envelope vertices meet.
// Fills follow the rectilinear outer cycle (not interior door stubs).
std::vector<RasterSeg> close_exterior_loop(const std::vector<RasterSeg>& segs, double snap_mm,
                                           double max_fill_mm);

// Largest jump on the rectilinear outer cycle after snapping (0 = closed).
// Interior degree-1 vertices (door gaps) are not counted.
double largest_exterior_gap_mm(const std::vector<RasterSeg>& segs, double snap_mm);

// Split axis-aligned segments at crossings and T-junctions so the graph
// sees corner/T vertices, not only raw endpoints.
std::vector<RasterSeg> split_at_nodes(const std::vector<RasterSeg>& segs, double snap_mm);

// Grow a segment along its axis until it meets an orthogonal wall (or max_extend).
RasterSeg extend_segment_to_hits(const RasterSeg& seg, const std::vector<RasterSeg>& others,
                                 double max_extend_mm, double snap_mm);

domain::WindowSubtype classify_window_subtype(double sill_mm, double height_mm, double storey_mm,
                                              bool on_bay_bump);

std::vector<BayBump> detect_bay_bumps(const std::vector<RasterSeg>& segs);

bool point_on_bay(const BayBump& bump, double x, double y, double tol_mm);

RasterSeg detected_wall_to_seg(const ports::DetectedWall& wall);
ports::DetectedWall seg_to_detected_wall(const RasterSeg& seg);

}  // namespace toporoom::adapters
