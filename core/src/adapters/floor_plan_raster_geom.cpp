#include "toporoom/adapters/floor_plan_raster_geom.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <set>
#include <utility>
#include <vector>

namespace toporoom::adapters {
namespace {

bool is_horizontal(const RasterSeg& s) {
  return std::abs(s.y1 - s.y0) <= std::abs(s.x1 - s.x0);
}

void normalize(RasterSeg* s) {
  if (is_horizontal(*s)) {
    s->y0 = s->y1 = 0.5 * (s->y0 + s->y1);
    if (s->x1 < s->x0) std::swap(s->x0, s->x1);
  } else {
    s->x0 = s->x1 = 0.5 * (s->x0 + s->x1);
    if (s->y1 < s->y0) std::swap(s->y0, s->y1);
  }
}

double length_of(const RasterSeg& s) { return std::hypot(s.x1 - s.x0, s.y1 - s.y0); }

struct Cluster1 {
  double lo = 0;
  double hi = 0;
  double mean = 0;
};

std::vector<Cluster1> make_clusters(std::vector<double> values, double snap) {
  std::vector<Cluster1> out;
  if (values.empty()) return out;
  std::sort(values.begin(), values.end());
  std::size_t i = 0;
  while (i < values.size()) {
    std::size_t j = i + 1;
    double sum = values[i];
    int n = 1;
    while (j < values.size() && values[j] - values[i] <= snap) {
      sum += values[j];
      ++n;
      ++j;
    }
    out.push_back(Cluster1{values[i], values[j - 1], sum / static_cast<double>(n)});
    i = j;
  }
  return out;
}

double apply_cluster(const std::vector<Cluster1>& clusters, double v) {
  double best = v;
  double best_d = 1e18;
  for (const auto& c : clusters) {
    if (v + 1e-6 >= c.lo && v - 1e-6 <= c.hi) return c.mean;
    const double d = std::min(std::abs(v - c.lo), std::abs(v - c.hi));
    if (d < best_d) {
      best_d = d;
      best = c.mean;
    }
  }
  return best;
}

struct Vtx {
  double x = 0;
  double y = 0;
};

using VKey = std::pair<int, int>;

VKey quantize(double x, double y, double q) {
  const double qq = std::max(q, 1.0);
  return {static_cast<int>(std::lround(x / qq)), static_cast<int>(std::lround(y / qq))};
}

std::map<VKey, std::vector<VKey>> adjacency(const std::vector<RasterSeg>& segs, double q,
                                            std::map<VKey, Vtx>* nodes) {
  std::map<VKey, std::vector<VKey>> adj;
  auto add = [&](double x, double y) {
    const VKey k = quantize(x, y, q);
    auto it = nodes->find(k);
    if (it == nodes->end()) {
      (*nodes)[k] = Vtx{x, y};
    } else {
      it->second.x = 0.5 * (it->second.x + x);
      it->second.y = 0.5 * (it->second.y + y);
    }
    return k;
  };
  for (const auto& s : segs) {
    if (length_of(s) < 20.0) continue;
    const VKey a = add(s.x0, s.y0);
    const VKey b = add(s.x1, s.y1);
    if (a == b) continue;
    adj[a].push_back(b);
    adj[b].push_back(a);
  }
  for (auto& kv : adj) {
    auto& nbrs = kv.second;
    std::sort(nbrs.begin(), nbrs.end());
    nbrs.erase(std::unique(nbrs.begin(), nbrs.end()), nbrs.end());
  }
  return adj;
}

int degree_of(const std::map<VKey, std::vector<VKey>>& adj, VKey k) {
  auto it = adj.find(k);
  if (it == adj.end()) return 0;
  return static_cast<int>(it->second.size());
}

// +x, +y, -x, -y
int dir_of(const Vtx& a, const Vtx& b) {
  if (std::abs(b.x - a.x) >= std::abs(b.y - a.y)) return b.x >= a.x ? 0 : 2;
  return b.y >= a.y ? 1 : 3;
}

VKey pick_start(const std::map<VKey, Vtx>& nodes) {
  VKey best = nodes.begin()->first;
  Vtx bp = nodes.begin()->second;
  for (const auto& kv : nodes) {
    if (kv.second.y < bp.y - 1e-6 || (std::abs(kv.second.y - bp.y) <= 1e-6 && kv.second.x < bp.x)) {
      best = kv.first;
      bp = kv.second;
    }
  }
  return best;
}

struct OuterGap {
  Vtx a;
  Vtx b;
  double dist = 0;
  bool axis = true;
};

// Walk the rectilinear outer cycle. Prefer unused edges whose midpoints lie
// farthest from the plan centre so T-junction stems into the interior are
// not followed. Interior door stubs are never visited.
std::vector<OuterGap> outer_cycle_gaps(const std::vector<RasterSeg>& segs, double snap_mm) {
  std::vector<OuterGap> gaps;
  if (segs.empty()) return gaps;
  const double q = std::max(1.0, snap_mm * 0.5);
  std::map<VKey, Vtx> nodes;
  const auto adj = adjacency(segs, q, &nodes);
  if (nodes.empty()) return gaps;

  double minx = 1e18, miny = 1e18, maxx = -1e18, maxy = -1e18;
  for (const auto& kv : nodes) {
    minx = std::min(minx, kv.second.x);
    miny = std::min(miny, kv.second.y);
    maxx = std::max(maxx, kv.second.x);
    maxy = std::max(maxy, kv.second.y);
  }
  const double cx = 0.5 * (minx + maxx);
  const double cy = 0.5 * (miny + maxy);

  const VKey start = pick_start(nodes);
  VKey cur = start;
  int incoming = 2;
  std::set<std::pair<VKey, VKey>> used_edges;
  VKey prev = start;
  bool have_prev = false;
  std::set<VKey> visited;
  visited.insert(start);
  int steps = 0;
  const int limit = static_cast<int>(nodes.size()) * 4 + 8;

  auto edge_key = [](VKey a, VKey b) {
    return a < b ? std::make_pair(a, b) : std::make_pair(b, a);
  };
  auto is_nbr = [&](VKey a, VKey b) {
    auto it = adj.find(a);
    if (it == adj.end()) return false;
    return std::find(it->second.begin(), it->second.end(), b) != it->second.end();
  };

  while (steps++ < limit) {
    const Vtx pc = nodes[cur];
    VKey best_nbr{};
    double best_score = -1e18;
    bool found = false;
    VKey best_rev{};
    bool found_rev = false;
    auto it = adj.find(cur);
    if (it != adj.end()) {
      for (VKey n : it->second) {
        if (used_edges.count(edge_key(cur, n))) continue;
        const bool rev = have_prev && n == prev;
        const Vtx& tn = nodes[n];
        const double mx = 0.5 * (pc.x + tn.x);
        const double my = 0.5 * (pc.y + tn.y);
        double score = std::hypot(mx - cx, my - cy);
        if (dir_of(pc, tn) == incoming) score += 400.0;
        if (rev) {
          if (!found_rev || score > -1e18) {
            best_rev = n;
            found_rev = true;
          }
          continue;
        }
        if (!found || score > best_score) {
          best_score = score;
          best_nbr = n;
          found = true;
        }
      }
    }
    if (found) {
      used_edges.insert(edge_key(cur, best_nbr));
      incoming = dir_of(pc, nodes[best_nbr]);
      prev = cur;
      have_prev = true;
      cur = best_nbr;
      visited.insert(cur);
      if (cur == start) break;
      continue;
    }
    if (found_rev && best_rev == start && have_prev) break;
    if (have_prev && is_nbr(cur, start)) break;

    VKey best_j{};
    double best_d = 1e18;
    bool best_axis = true;
    bool have_j = false;
    for (const auto& kv : nodes) {
      if (kv.first == cur) continue;
      if (have_prev && kv.first == prev) continue;
      if (visited.count(kv.first) && kv.first != start) continue;
      const Vtx& t = kv.second;
      const bool share_x = std::abs(pc.x - t.x) <= snap_mm;
      const bool share_y = std::abs(pc.y - t.y) <= snap_mm;
      double dist = 1e18;
      bool axis = true;
      if (share_x) {
        dist = std::abs(pc.y - t.y);
      } else if (share_y) {
        dist = std::abs(pc.x - t.x);
      } else {
        dist = std::abs(pc.x - t.x) + std::abs(pc.y - t.y);
        axis = false;
      }
      if (dist <= snap_mm || dist >= 1e17) continue;
      const double mx = 0.5 * (pc.x + t.x);
      const double my = 0.5 * (pc.y + t.y);
      const double outer = std::hypot(mx - cx, my - cy);
      const double score = dist - 0.15 * outer + (axis ? 0.0 : 250.0);
      if (score < best_d) {
        best_d = score;
        best_j = kv.first;
        best_axis = axis;
        have_j = true;
      }
    }
    if (!have_j) break;
    if (best_j == start) break;
    const Vtx& tb = nodes[best_j];
    const double gap_d = best_axis ? (std::abs(pc.x - tb.x) <= snap_mm ? std::abs(pc.y - tb.y)
                                                                       : std::abs(pc.x - tb.x))
                                   : (std::abs(pc.x - tb.x) + std::abs(pc.y - tb.y));
    gaps.push_back(OuterGap{pc, tb, gap_d, best_axis});
    used_edges.insert(edge_key(cur, best_j));
    incoming = dir_of(pc, tb);
    prev = cur;
    have_prev = true;
    cur = best_j;
    visited.insert(cur);
    if (cur == start) break;
  }
  return gaps;
}

RasterSeg make_axis_fill(const Vtx& a, const Vtx& b, double snap_mm) {
  RasterSeg fill;
  fill.kind = domain::WallKind::ShearWall;
  fill.thickness_mm = 200;
  if (std::abs(a.x - b.x) <= snap_mm) {
    fill.x0 = fill.x1 = 0.5 * (a.x + b.x);
    fill.y0 = std::min(a.y, b.y);
    fill.y1 = std::max(a.y, b.y);
  } else {
    fill.y0 = fill.y1 = 0.5 * (a.y + b.y);
    fill.x0 = std::min(a.x, b.x);
    fill.x1 = std::max(a.x, b.x);
  }
  return fill;
}

}  // namespace

std::vector<RasterSeg> split_at_nodes(const std::vector<RasterSeg>& segs, double snap_mm) {
  if (segs.size() < 2) return segs;
  std::vector<std::vector<double>> cuts(segs.size());
  auto on_span = [&](double v, double a, double b) {
    const double lo = std::min(a, b);
    const double hi = std::max(a, b);
    return v >= lo - snap_mm && v <= hi + snap_mm;
  };
  for (std::size_t i = 0; i < segs.size(); ++i) {
    RasterSeg a = segs[i];
    normalize(&a);
    const bool ah = is_horizontal(a);
    for (std::size_t j = i + 1; j < segs.size(); ++j) {
      RasterSeg b = segs[j];
      normalize(&b);
      const bool bh = is_horizontal(b);
      if (ah == bh) continue;
      const RasterSeg& h = ah ? a : b;
      const RasterSeg& v = ah ? b : a;
      const std::size_t hi = ah ? i : j;
      const std::size_t vi = ah ? j : i;
      if (!on_span(v.x0, h.x0, h.x1) || !on_span(h.y0, v.y0, v.y1)) continue;
      cuts[hi].push_back(v.x0);
      cuts[vi].push_back(h.y0);
    }
  }
  std::vector<RasterSeg> out;
  out.reserve(segs.size() * 2);
  for (std::size_t i = 0; i < segs.size(); ++i) {
    RasterSeg s = segs[i];
    normalize(&s);
    auto& c = cuts[i];
    if (c.empty()) {
      out.push_back(s);
      continue;
    }
    const bool horiz = is_horizontal(s);
    c.push_back(horiz ? s.x0 : s.y0);
    c.push_back(horiz ? s.x1 : s.y1);
    std::sort(c.begin(), c.end());
    c.erase(std::unique(c.begin(), c.end(),
                        [&](double x, double y) { return std::abs(x - y) <= snap_mm * 0.5; }),
            c.end());
    for (std::size_t k = 1; k < c.size(); ++k) {
      if (c[k] - c[k - 1] < 40.0) continue;
      RasterSeg p = s;
      if (horiz) {
        p.x0 = c[k - 1];
        p.x1 = c[k];
      } else {
        p.y0 = c[k - 1];
        p.y1 = c[k];
      }
      out.push_back(p);
    }
  }
  return out.empty() ? segs : out;
}

RasterSeg extend_segment_to_hits(const RasterSeg& seg, const std::vector<RasterSeg>& others,
                                 double max_extend_mm, double snap_mm) {
  RasterSeg s = seg;
  normalize(&s);
  const bool horiz = is_horizontal(s);
  auto try_end = [&](bool min_end) {
    double best = max_extend_mm + 1.0;
    double hit_at = min_end ? (horiz ? s.x0 : s.y0) : (horiz ? s.x1 : s.y1);
    const double pos = horiz ? s.y0 : s.x0;
    const double lo = horiz ? s.x0 : s.y0;
    const double hi = horiz ? s.x1 : s.y1;
    for (const auto& o : others) {
      RasterSeg oo = o;
      normalize(&oo);
      if (is_horizontal(oo) == horiz) continue;
      if (horiz) {
        const double ox = oo.x0;
        const double oy0 = std::min(oo.y0, oo.y1);
        const double oy1 = std::max(oo.y0, oo.y1);
        if (pos < oy0 - snap_mm || pos > oy1 + snap_mm) continue;
        if (min_end) {
          if (ox > lo - 1.0 || lo - ox > max_extend_mm) continue;
          const double d = lo - ox;
          if (d < best && d > snap_mm * 0.25) {
            best = d;
            hit_at = ox;
          }
        } else {
          if (ox < hi + 1.0 || ox - hi > max_extend_mm) continue;
          const double d = ox - hi;
          if (d < best && d > snap_mm * 0.25) {
            best = d;
            hit_at = ox;
          }
        }
      } else {
        const double oy = oo.y0;
        const double ox0 = std::min(oo.x0, oo.x1);
        const double ox1 = std::max(oo.x0, oo.x1);
        if (pos < ox0 - snap_mm || pos > ox1 + snap_mm) continue;
        if (min_end) {
          if (oy > lo - 1.0 || lo - oy > max_extend_mm) continue;
          const double d = lo - oy;
          if (d < best && d > snap_mm * 0.25) {
            best = d;
            hit_at = oy;
          }
        } else {
          if (oy < hi + 1.0 || oy - hi > max_extend_mm) continue;
          const double d = oy - hi;
          if (d < best && d > snap_mm * 0.25) {
            best = d;
            hit_at = oy;
          }
        }
      }
    }
    if (best <= max_extend_mm) {
      if (horiz) {
        if (min_end) s.x0 = hit_at;
        else s.x1 = hit_at;
      } else {
        if (min_end) s.y0 = hit_at;
        else s.y1 = hit_at;
      }
    }
  };
  try_end(true);
  try_end(false);
  normalize(&s);
  return s;
}

std::vector<RasterSeg> merge_collinear_segments(const std::vector<RasterSeg>& segs,
                                                double snap_mm, double gap_merge_mm) {
  std::vector<RasterSeg> work = segs;
  for (auto& s : work) normalize(&s);
  std::vector<RasterSeg> out;
  auto merge_group = [&](std::vector<RasterSeg> group, bool horiz) {
    if (group.empty()) return;
    auto tee_in_gap = [&](double pos, double gap_lo, double gap_hi) {
      if (gap_hi <= gap_lo + snap_mm) return false;
      for (const auto& s : work) {
        if (is_horizontal(s) == horiz) continue;
        const double op = horiz ? s.x0 : s.y0;
        if (op <= gap_lo + snap_mm || op >= gap_hi - snap_mm) continue;
        const double a0 = horiz ? std::min(s.y0, s.y1) : std::min(s.x0, s.x1);
        const double a1 = horiz ? std::max(s.y0, s.y1) : std::max(s.x0, s.x1);
        if (pos >= a0 - snap_mm && pos <= a1 + snap_mm) return true;
      }
      return false;
    };
    std::sort(group.begin(), group.end(), [&](const RasterSeg& a, const RasterSeg& b) {
      if (horiz) {
        if (std::abs(a.y0 - b.y0) > snap_mm) return a.y0 < b.y0;
        return a.x0 < b.x0;
      }
      if (std::abs(a.x0 - b.x0) > snap_mm) return a.x0 < b.x0;
      return a.y0 < b.y0;
    });
    std::vector<char> used(group.size(), 0);
    for (std::size_t i = 0; i < group.size(); ++i) {
      if (used[i]) continue;
      RasterSeg cur = group[i];
      used[i] = 1;
      bool grew = true;
      while (grew) {
        grew = false;
        for (std::size_t j = 0; j < group.size(); ++j) {
          if (used[j] || cur.kind != group[j].kind) continue;
          RasterSeg o = group[j];
          if (horiz) {
            if (std::abs(o.y0 - cur.y0) > snap_mm) continue;
            if (o.x0 > cur.x1 + gap_merge_mm + snap_mm) continue;
            if (o.x1 < cur.x0 - gap_merge_mm - snap_mm) continue;
            if (o.x0 > cur.x1 + 1.0 && o.x0 - cur.x1 > gap_merge_mm) continue;
            if (o.x0 > cur.x1 + snap_mm && tee_in_gap(cur.y0, cur.x1, o.x0)) continue;
            if (o.x1 + snap_mm < cur.x0 && tee_in_gap(cur.y0, o.x1, cur.x0)) continue;
            cur.x0 = std::min(cur.x0, o.x0);
            cur.x1 = std::max(cur.x1, o.x1);
            cur.y0 = cur.y1 = 0.5 * (cur.y0 + o.y0);
            cur.thickness_mm = std::max(cur.thickness_mm, o.thickness_mm);
            used[j] = 1;
            grew = true;
          } else {
            if (std::abs(o.x0 - cur.x0) > snap_mm) continue;
            if (o.y0 > cur.y1 + gap_merge_mm + snap_mm) continue;
            if (o.y1 < cur.y0 - gap_merge_mm - snap_mm) continue;
            if (o.y0 > cur.y1 + 1.0 && o.y0 - cur.y1 > gap_merge_mm) continue;
            if (o.y0 > cur.y1 + snap_mm && tee_in_gap(cur.x0, cur.y1, o.y0)) continue;
            if (o.y1 + snap_mm < cur.y0 && tee_in_gap(cur.x0, o.y1, cur.y0)) continue;
            cur.y0 = std::min(cur.y0, o.y0);
            cur.y1 = std::max(cur.y1, o.y1);
            cur.x0 = cur.x1 = 0.5 * (cur.x0 + o.x0);
            cur.thickness_mm = std::max(cur.thickness_mm, o.thickness_mm);
            used[j] = 1;
            grew = true;
          }
        }
      }
      if (length_of(cur) >= 80.0) out.push_back(cur);
    }
  };

  for (bool horiz : {true, false}) {
    std::vector<RasterSeg> group;
    for (const auto& s : work) {
      if (is_horizontal(s) == horiz) group.push_back(s);
    }
    merge_group(std::move(group), horiz);
  }
  return out;
}

std::vector<RasterSeg> snap_endpoints(const std::vector<RasterSeg>& segs, double snap_mm) {
  if (segs.empty()) return segs;
  std::vector<double> xs;
  std::vector<double> ys;
  xs.reserve(segs.size() * 2);
  ys.reserve(segs.size() * 2);
  for (const auto& s : segs) {
    xs.push_back(s.x0);
    xs.push_back(s.x1);
    ys.push_back(s.y0);
    ys.push_back(s.y1);
  }
  const auto xc = make_clusters(xs, snap_mm);
  const auto yc = make_clusters(ys, snap_mm);
  std::vector<RasterSeg> out;
  out.reserve(segs.size());
  for (auto s : segs) {
    s.x0 = apply_cluster(xc, s.x0);
    s.x1 = apply_cluster(xc, s.x1);
    s.y0 = apply_cluster(yc, s.y0);
    s.y1 = apply_cluster(yc, s.y1);
    normalize(&s);
    if (length_of(s) < 40.0) continue;
    out.push_back(s);
  }
  return out;
}

double largest_exterior_gap_mm(const std::vector<RasterSeg>& segs, double snap_mm) {
  if (segs.empty()) return 1.0e9;
  const auto snapped = snap_endpoints(segs, snap_mm);
  if (snapped.empty()) return 1.0e9;
  double minx = 1e18, miny = 1e18, maxx = -1e18, maxy = -1e18;
  for (const auto& s : snapped) {
    minx = std::min({minx, s.x0, s.x1});
    miny = std::min({miny, s.y0, s.y1});
    maxx = std::max({maxx, s.x0, s.x1});
    maxy = std::max({maxy, s.y0, s.y1});
  }
  if (maxx - minx < 80.0 || maxy - miny < 80.0) return 1.0e9;
  const double cell = std::max(40.0, snap_mm * 0.5);
  const int pad = 2;
  const int W = static_cast<int>(std::ceil((maxx - minx) / cell)) + pad * 2 + 1;
  const int H = static_cast<int>(std::ceil((maxy - miny) / cell)) + pad * 2 + 1;
  if (W < 4 || H < 4) return 1.0e9;
  std::vector<std::uint8_t> grid(static_cast<std::size_t>(W) * static_cast<std::size_t>(H), 0);
  auto at = [&](int x, int y) -> std::uint8_t& {
    return grid[static_cast<std::size_t>(y * W + x)];
  };
  auto stamp = [&](double x0, double y0, double x1, double y1) {
    int x = pad + static_cast<int>(std::lround((x0 - minx) / cell));
    int y = pad + static_cast<int>(std::lround((y0 - miny) / cell));
    const int xend = pad + static_cast<int>(std::lround((x1 - minx) / cell));
    const int yend = pad + static_cast<int>(std::lround((y1 - miny) / cell));
    const int dx = std::abs(xend - x);
    const int dy = std::abs(yend - y);
    const int sx = x < xend ? 1 : -1;
    const int sy = y < yend ? 1 : -1;
    int err = dx - dy;
    while (true) {
      if (x >= 0 && y >= 0 && x < W && y < H) at(x, y) = 1;
      if (x == xend && y == yend) break;
      const int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
  };
  for (const auto& s : snapped) stamp(s.x0, s.y0, s.x1, s.y1);

  std::vector<int> stack;
  stack.push_back(0);
  at(0, 0) = 2;
  const int dirs[4][2] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
  while (!stack.empty()) {
    const int cur = stack.back();
    stack.pop_back();
    const int cx = cur % W;
    const int cy = cur / W;
    for (const auto& d : dirs) {
      const int nx = cx + d[0];
      const int ny = cy + d[1];
      if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
      if (at(nx, ny) != 0) continue;
      at(nx, ny) = 2;
      stack.push_back(ny * W + nx);
    }
  }

  std::vector<std::uint8_t> seen(grid.size(), 0);
  int best_area = 0;
  for (int y = 0; y < H; ++y) {
    for (int x = 0; x < W; ++x) {
      const int i = y * W + x;
      if (grid[static_cast<std::size_t>(i)] != 0 || seen[static_cast<std::size_t>(i)]) continue;
      std::vector<int> q;
      q.push_back(i);
      seen[static_cast<std::size_t>(i)] = 1;
      int area = 0;
      std::size_t head = 0;
      while (head < q.size()) {
        const int cur = q[head++];
        ++area;
        const int cx = cur % W;
        const int cy = cur / W;
        for (const auto& d : dirs) {
          const int nx = cx + d[0];
          const int ny = cy + d[1];
          if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
          const int ni = ny * W + nx;
          if (grid[static_cast<std::size_t>(ni)] != 0 || seen[static_cast<std::size_t>(ni)]) continue;
          seen[static_cast<std::size_t>(ni)] = 1;
          q.push_back(ni);
        }
      }
      best_area = std::max(best_area, area);
    }
  }
  const double area_mm2 = static_cast<double>(best_area) * cell * cell;
  if (area_mm2 >= 2.0e6) return 0.0;
  return 1.0e9;
}

std::vector<RasterSeg> close_exterior_loop(const std::vector<RasterSeg>& segs, double snap_mm,
                                           double max_fill_mm) {
  auto work = split_at_nodes(snap_endpoints(segs, snap_mm), snap_mm);
  int guard = 0;
  while (guard++ < 48) {
    bool grew = false;
    std::vector<RasterSeg> extended;
    extended.reserve(work.size());
    for (const auto& s : work) {
      RasterSeg e = extend_segment_to_hits(s, work, std::min(max_fill_mm, 2000.0), snap_mm);
      if (std::abs(length_of(e) - length_of(s)) > snap_mm) grew = true;
      extended.push_back(e);
    }
    work = snap_endpoints(extended, snap_mm);
    const auto noded = split_at_nodes(work, snap_mm);
    const auto gaps = outer_cycle_gaps(noded, snap_mm);
    int added = 0;
    for (const auto& pick : gaps) {
      if (pick.dist <= snap_mm) continue;
      if (pick.axis) {
        if (pick.dist > max_fill_mm) continue;
        RasterSeg fill = make_axis_fill(pick.a, pick.b, snap_mm);
        if (length_of(fill) > snap_mm) {
          work.push_back(fill);
          grew = true;
          ++added;
        }
        continue;
      }
      const double dx = std::abs(pick.a.x - pick.b.x);
      const double dy = std::abs(pick.a.y - pick.b.y);
      if (dx > max_fill_mm || dy > max_fill_mm) continue;
      double minx = 1e18, miny = 1e18, maxx = -1e18, maxy = -1e18;
      for (const auto& s : work) {
        minx = std::min({minx, s.x0, s.x1});
        miny = std::min({miny, s.y0, s.y1});
        maxx = std::max({maxx, s.x0, s.x1});
        maxy = std::max({maxy, s.y0, s.y1});
      }
      auto exterior_score = [&](double x, double y) {
        return std::min({std::abs(x - minx), std::abs(x - maxx), std::abs(y - miny),
                         std::abs(y - maxy)});
      };
      const Vtx c1{pick.b.x, pick.a.y};
      const Vtx c2{pick.a.x, pick.b.y};
      const Vtx corner = exterior_score(c1.x, c1.y) <= exterior_score(c2.x, c2.y) ? c1 : c2;
      RasterSeg f0 = make_axis_fill(pick.a, corner, snap_mm);
      RasterSeg f1 = make_axis_fill(corner, pick.b, snap_mm);
      if (length_of(f0) > snap_mm) work.push_back(f0);
      if (length_of(f1) > snap_mm) work.push_back(f1);
      grew = true;
      ++added;
      if (added >= 4) break;
    }
    if (!grew) break;
    work = merge_collinear_segments(work, snap_mm, std::max(snap_mm * 2.0, 200.0));
    work = snap_endpoints(work, snap_mm);
  }

  // Degree-1 vertices on the bounding box: L/axis fill to close the envelope
  // (阳台 south, missing corners) without plugging interior door stubs.
  {
    const double q = std::max(1.0, snap_mm * 0.5);
    std::map<VKey, Vtx> nodes;
    const auto adj = adjacency(work, q, &nodes);
    double minx = 1e18, miny = 1e18, maxx = -1e18, maxy = -1e18;
    for (const auto& kv : nodes) {
      minx = std::min(minx, kv.second.x);
      miny = std::min(miny, kv.second.y);
      maxx = std::max(maxx, kv.second.x);
      maxy = std::max(maxy, kv.second.y);
    }
    const double tol = std::max(snap_mm, 200.0);
    auto on_bbox = [&](const Vtx& p) {
      return p.x <= minx + tol || p.x >= maxx - tol || p.y <= miny + tol || p.y >= maxy - tol;
    };
    for (const auto& kv : nodes) {
      if (degree_of(adj, kv.first) != 1) continue;
      const Vtx& pa = kv.second;
      if (!on_bbox(pa)) continue;
      VKey skip = adj.at(kv.first).empty() ? kv.first : adj.at(kv.first)[0];
      double best = max_fill_mm + 1.0;
      Vtx tb{};
      bool axis = true;
      bool have = false;
      for (const auto& o : nodes) {
        if (o.first == kv.first || o.first == skip) continue;
        if (!on_bbox(o.second)) continue;
        const Vtx& pb = o.second;
        const bool share_x = std::abs(pa.x - pb.x) <= snap_mm;
        const bool share_y = std::abs(pa.y - pb.y) <= snap_mm;
        double dist;
        bool ax = true;
        if (share_x) dist = std::abs(pa.y - pb.y);
        else if (share_y) dist = std::abs(pa.x - pb.x);
        else {
          dist = std::max(std::abs(pa.x - pb.x), std::abs(pa.y - pb.y));
          ax = false;
          if (std::abs(pa.x - pb.x) > max_fill_mm || std::abs(pa.y - pb.y) > max_fill_mm) continue;
        }
        if (dist <= snap_mm || dist > max_fill_mm) continue;
        if (dist < best) {
          best = dist;
          tb = pb;
          axis = ax;
          have = true;
        }
      }
      if (!have) continue;
      if (axis) {
        RasterSeg fill = make_axis_fill(pa, tb, snap_mm);
        if (length_of(fill) > snap_mm) work.push_back(fill);
      } else {
        const Vtx c1{tb.x, pa.y};
        RasterSeg f0 = make_axis_fill(pa, c1, snap_mm);
        RasterSeg f1 = make_axis_fill(c1, tb, snap_mm);
        if (length_of(f0) > snap_mm) work.push_back(f0);
        if (length_of(f1) > snap_mm) work.push_back(f1);
      }
    }
  }
  work = merge_collinear_segments(work, snap_mm, std::max(snap_mm * 2.0, 200.0));
  return snap_endpoints(work, snap_mm);
}

domain::WindowSubtype classify_window_subtype(double sill_mm, double height_mm, double storey_mm,
                                              bool on_bay_bump) {
  if (on_bay_bump) return domain::WindowSubtype::Bay;
  const double storey = std::max(storey_mm, 1.0);
  if (sill_mm <= 80.0 && height_mm >= storey * 0.82) return domain::WindowSubtype::FloorCeiling;
  return domain::WindowSubtype::Standard;
}

std::vector<BayBump> detect_bay_bumps(const std::vector<RasterSeg>& segs) {
  std::vector<BayBump> out;
  auto add_unique = [&](BayBump bump) {
    if (bump.x1 - bump.x0 < 200 || bump.y1 - bump.y0 < 200) return;
    if (bump.x1 - bump.x0 > 2800 && bump.y1 - bump.y0 > 2800) return;
    for (const auto& e : out) {
      const double ix0 = std::max(e.x0, bump.x0);
      const double iy0 = std::max(e.y0, bump.y0);
      const double ix1 = std::min(e.x1, bump.x1);
      const double iy1 = std::min(e.y1, bump.y1);
      if (ix1 > ix0 && iy1 > iy0) return;
    }
    out.push_back(bump);
  };

  // U-pocket: two parallel walls + an orthogonal connector. The short stub
  // beyond the connector is the 飘窗 extrusion (works even when the sides are
  // long bedroom walls).
  for (std::size_t i = 0; i < segs.size(); ++i) {
    for (std::size_t j = i + 1; j < segs.size(); ++j) {
      const RasterSeg& a = segs[i];
      const RasterSeg& b = segs[j];
      if (is_horizontal(a) != is_horizontal(b)) continue;
      const bool horiz = is_horizontal(a);
      if (horiz) {
        const double dy = std::abs(a.y0 - b.y0);
        if (dy < 400.0 || dy > 2200.0) continue;
        const double ov0 = std::max(a.x0, b.x0);
        const double ov1 = std::min(a.x1, b.x1);
        if (ov1 - ov0 < 250.0) continue;
        const double y0 = std::min(a.y0, b.y0);
        const double y1 = std::max(a.y0, b.y0);
        for (const auto& c : segs) {
          if (is_horizontal(c)) continue;
          if (c.x0 < ov0 - 80 || c.x0 > ov1 + 80) continue;
          if (std::min(c.y1, y1) - std::max(c.y0, y0) < dy * 0.6) continue;
          const double west_stub = c.x0 - ov0;
          const double east_stub = ov1 - c.x0;
          BayBump bump;
          bump.y0 = y0;
          bump.y1 = y1;
          bump.ori = 'V';
          if (west_stub >= 350.0 && west_stub <= 1800.0 && west_stub < east_stub) {
            bump.x0 = ov0;
            bump.x1 = c.x0;
            add_unique(bump);
          } else if (east_stub >= 350.0 && east_stub <= 1800.0 && east_stub < west_stub) {
            bump.x0 = c.x0;
            bump.x1 = ov1;
            add_unique(bump);
          }
        }
      } else {
        const double dx = std::abs(a.x0 - b.x0);
        if (dx < 400.0 || dx > 2200.0) continue;
        const double ov0 = std::max(a.y0, b.y0);
        const double ov1 = std::min(a.y1, b.y1);
        if (ov1 - ov0 < 250.0) continue;
        const double x0 = std::min(a.x0, b.x0);
        const double x1 = std::max(a.x0, b.x0);
        for (const auto& c : segs) {
          if (!is_horizontal(c)) continue;
          if (c.y0 < ov0 - 80 || c.y0 > ov1 + 80) continue;
          if (std::min(c.x1, x1) - std::max(c.x0, x0) < dx * 0.6) continue;
          const double south_stub = c.y0 - ov0;
          const double north_stub = ov1 - c.y0;
          BayBump bump;
          bump.x0 = x0;
          bump.x1 = x1;
          bump.ori = 'H';
          if (south_stub >= 350.0 && south_stub <= 1800.0 && south_stub < north_stub) {
            bump.y0 = ov0;
            bump.y1 = c.y0;
            add_unique(bump);
          } else if (north_stub >= 350.0 && north_stub <= 1800.0 && north_stub < south_stub) {
            bump.y0 = c.y0;
            bump.y1 = ov1;
            add_unique(bump);
          }
        }
      }
    }
  }
  return out;
}

bool point_on_bay(const BayBump& bump, double x, double y, double tol_mm) {
  return x >= bump.x0 - tol_mm && x <= bump.x1 + tol_mm && y >= bump.y0 - tol_mm &&
         y <= bump.y1 + tol_mm;
}

RasterSeg detected_wall_to_seg(const ports::DetectedWall& wall) {
  RasterSeg s;
  s.x0 = wall.start_x;
  s.y0 = wall.start_y;
  s.x1 = wall.end_x;
  s.y1 = wall.end_y;
  s.thickness_mm = wall.thickness_mm;
  s.kind = wall.kind;
  s.id = wall.id;
  return s;
}

ports::DetectedWall seg_to_detected_wall(const RasterSeg& seg) {
  ports::DetectedWall w;
  w.id = seg.id;
  w.start_x = seg.x0;
  w.start_y = seg.y0;
  w.end_x = seg.x1;
  w.end_y = seg.y1;
  w.thickness_mm = seg.thickness_mm;
  w.kind = seg.kind;
  w.height_mm = 2800;
  return w;
}

}  // namespace toporoom::adapters
