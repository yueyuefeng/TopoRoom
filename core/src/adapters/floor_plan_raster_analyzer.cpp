#include "toporoom/adapters/floor_plan_raster_geom.hpp"
#include "toporoom/adapters/floor_plan_vision_adapters.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

namespace toporoom::adapters {
namespace {

struct Bar {
  char ori = 'H';  // 'H' or 'V'
  int x0 = 0;
  int y0 = 0;
  int x1 = 0;
  int y1 = 0;
  int length = 0;
  int thickness = 0;
};

int luma_of(const unsigned char* p) {
  return (299 * static_cast<int>(p[0]) + 587 * static_cast<int>(p[1]) +
          114 * static_cast<int>(p[2])) /
         1000;
}

int sat_of(const unsigned char* p) {
  const int r = p[0];
  const int g = p[1];
  const int b = p[2];
  return std::max(r, std::max(g, b)) - std::min(r, std::min(g, b));
}

const unsigned char* px(const RasterImage& image, int x, int y) {
  return &image.rgb[(static_cast<std::size_t>(y) * static_cast<std::size_t>(image.width) +
                     static_cast<std::size_t>(x)) *
                    3u];
}

std::vector<std::uint8_t> keep_large_cc(const std::vector<std::uint8_t>& mask, int w, int h,
                                        int min_area) {
  std::vector<std::uint8_t> out(mask.size(), 0);
  std::vector<std::uint8_t> seen(mask.size(), 0);
  std::vector<int> q;
  q.reserve(1024);
  const int dirs[4][2] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
  auto idx = [w](int x, int y) { return y * w + x; };
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      const int start = idx(x, y);
      if (!mask[static_cast<std::size_t>(start)] || seen[static_cast<std::size_t>(start)]) {
        continue;
      }
      q.clear();
      q.push_back(start);
      seen[static_cast<std::size_t>(start)] = 1;
      std::size_t head = 0;
      while (head < q.size()) {
        const int cur = q[head++];
        const int cx = cur % w;
        const int cy = cur / w;
        for (const auto& d : dirs) {
          const int nx = cx + d[0];
          const int ny = cy + d[1];
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          const int ni = idx(nx, ny);
          if (!mask[static_cast<std::size_t>(ni)] || seen[static_cast<std::size_t>(ni)]) continue;
          seen[static_cast<std::size_t>(ni)] = 1;
          q.push_back(ni);
        }
      }
      if (static_cast<int>(q.size()) < min_area) continue;
      for (int i : q) out[static_cast<std::size_t>(i)] = 1;
    }
  }
  return out;
}

double overlap_frac(const Bar& a, const Bar& b) {
  const int ix0 = std::max(a.x0, b.x0);
  const int iy0 = std::max(a.y0, b.y0);
  const int ix1 = std::min(a.x1, b.x1);
  const int iy1 = std::min(a.y1, b.y1);
  if (ix1 < ix0 || iy1 < iy0) return 0;
  const double inter =
      static_cast<double>(ix1 - ix0 + 1) * static_cast<double>(iy1 - iy0 + 1);
  const double area =
      static_cast<double>(a.x1 - a.x0 + 1) * static_cast<double>(a.y1 - a.y0 + 1);
  return inter / std::max(area, 1.0);
}

std::vector<Bar> extract_bars(const std::vector<std::uint8_t>& mask, int w, int h, int min_len,
                              int min_thick, int max_thick, double fill) {
  std::vector<Bar> bars;
  auto at = [&](int x, int y) -> std::uint8_t {
    return mask[static_cast<std::size_t>(y * w + x)];
  };
  for (int y = 0; y < h; ++y) {
    int x = 0;
    while (x < w) {
      if (!at(x, y)) {
        ++x;
        continue;
      }
      const int x0 = x;
      while (x < w && at(x, y)) ++x;
      const int x1 = x - 1;
      if (x1 - x0 + 1 < min_len) continue;
      int y1 = y;
      while (y1 + 1 < h) {
        int filled = 0;
        for (int xx = x0; xx <= x1; ++xx) filled += at(xx, y1 + 1) ? 1 : 0;
        if (filled < fill * static_cast<double>(x1 - x0 + 1)) break;
        ++y1;
      }
      const int th = y1 - y + 1;
      const int ln = x1 - x0 + 1;
      if (th >= min_thick && th <= max_thick && ln >= min_len && ln >= th) {
        bars.push_back(Bar{'H', x0, y, x1, y1, ln, th});
      }
    }
  }
  for (int x = 0; x < w; ++x) {
    int y = 0;
    while (y < h) {
      if (!at(x, y)) {
        ++y;
        continue;
      }
      const int y0 = y;
      while (y < h && at(x, y)) ++y;
      const int y1 = y - 1;
      if (y1 - y0 + 1 < min_len) continue;
      int x1 = x;
      while (x1 + 1 < w) {
        int filled = 0;
        for (int yy = y0; yy <= y1; ++yy) filled += at(x1 + 1, yy) ? 1 : 0;
        if (filled < fill * static_cast<double>(y1 - y0 + 1)) break;
        ++x1;
      }
      const int th = x1 - x + 1;
      const int ln = y1 - y0 + 1;
      if (th >= min_thick && th <= max_thick && ln >= min_len && ln >= th) {
        bars.push_back(Bar{'V', x, y0, x1, y1, ln, th});
      }
    }
  }
  std::sort(bars.begin(), bars.end(), [](const Bar& a, const Bar& b) {
    return a.length * a.thickness > b.length * b.thickness;
  });
  std::vector<Bar> kept;
  kept.reserve(bars.size());
  for (const Bar& b : bars) {
    bool dominated = false;
    for (const Bar& k : kept) {
      if (k.ori == b.ori && overlap_frac(b, k) > 0.55) {
        dominated = true;
        break;
      }
      if (k.ori != b.ori && overlap_frac(b, k) > 0.72 && k.length >= static_cast<int>(b.length * 0.9)) {
        dominated = true;
        break;
      }
    }
    if (!dominated) kept.push_back(b);
  }
  return kept;
}

bool near_envelope(const Bar& b, int bx0, int by0, int bx1, int by1, int margin) {
  if (b.ori == 'H') {
    const int cy = (b.y0 + b.y1) / 2;
    return std::abs(cy - by0) <= margin || std::abs(cy - by1) <= margin + 6;
  }
  const int cx = (b.x0 + b.x1) / 2;
  return std::abs(cx - bx0) <= margin || std::abs(cx - bx1) <= margin;
}

struct Centerline {
  char ori = 'H';
  double a0 = 0;  // x0 or y0 along axis
  double a1 = 0;
  double pos = 0;  // y for H, x for V
  double thick = 0;
  char kind = 'S';  // S shear, M masonry
  int src = -1;
};

std::vector<Centerline> to_centerlines(const std::vector<Bar>& bars, char kind) {
  std::vector<Centerline> out;
  out.reserve(bars.size());
  for (std::size_t i = 0; i < bars.size(); ++i) {
    const Bar& b = bars[i];
    Centerline c;
    c.ori = b.ori;
    c.thick = static_cast<double>(b.thickness);
    c.kind = kind;
    c.src = static_cast<int>(i);
    if (b.ori == 'H') {
      c.a0 = b.x0;
      c.a1 = b.x1;
      c.pos = 0.5 * (b.y0 + b.y1);
    } else {
      c.a0 = b.y0;
      c.a1 = b.y1;
      c.pos = 0.5 * (b.x0 + b.x1);
    }
    if (c.a1 < c.a0) std::swap(c.a0, c.a1);
    out.push_back(c);
  }
  return out;
}

void downsample_if_needed(RasterImage* image) {
  const int maxd = std::max(image->width, image->height);
  if (maxd <= 1600) return;
  const int stride = (maxd + 1599) / 1600;
  const int nw = std::max(1, image->width / stride);
  const int nh = std::max(1, image->height / stride);
  std::vector<unsigned char> next(static_cast<std::size_t>(nw) * static_cast<std::size_t>(nh) *
                                  3u);
  for (int y = 0; y < nh; ++y) {
    for (int x = 0; x < nw; ++x) {
      const unsigned char* s = px(*image, std::min(image->width - 1, x * stride),
                                  std::min(image->height - 1, y * stride));
      unsigned char* d = &next[(static_cast<std::size_t>(y) * static_cast<std::size_t>(nw) +
                                static_cast<std::size_t>(x)) *
                               3u];
      d[0] = s[0];
      d[1] = s[1];
      d[2] = s[2];
    }
  }
  image->width = nw;
  image->height = nh;
  image->rgb.swap(next);
}

double dist_point_seg(double px, double py, double x0, double y0, double x1, double y1,
                      double* t_out) {
  const double dx = x1 - x0;
  const double dy = y1 - y0;
  const double len2 = dx * dx + dy * dy;
  if (len2 < 1e-9) {
    if (t_out) *t_out = 0;
    return std::hypot(px - x0, py - y0);
  }
  double t = ((px - x0) * dx + (py - y0) * dy) / len2;
  t = std::max(0.0, std::min(1.0, t));
  if (t_out) *t_out = t;
  const double qx = x0 + t * dx;
  const double qy = y0 + t * dy;
  return std::hypot(px - qx, py - qy);
}

std::string make_id(const char* prefix, int i) {
  return std::string(prefix) + std::to_string(i);
}

}  // namespace

ports::VisionResult analyze_floor_plan_raster(const RasterImage& source,
                                              const RasterAnalyzeOptions& options) {
  ports::VisionResult out;
  out.adapter_id = "raster";
  if (source.width <= 4 || source.height <= 4 || source.rgb.size() < 12) {
    out.error = "image too small";
    return out;
  }

  RasterImage image = source;
  downsample_if_needed(&image);
  const int w = image.width;
  const int h = image.height;

  std::vector<std::uint8_t> black_raw(static_cast<std::size_t>(w * h), 0);
  std::vector<std::uint8_t> gray_raw(static_cast<std::size_t>(w * h), 0);
  std::vector<std::uint8_t> win_raw(static_cast<std::size_t>(w * h), 0);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      const unsigned char* p = px(image, x, y);
      const int lu = luma_of(p);
      const int sat = sat_of(p);
      const int i = y * w + x;
      if (lu < 45 && sat < 35) black_raw[static_cast<std::size_t>(i)] = 1;
      if (lu >= 125 && lu < 168 && sat < 16 && !black_raw[static_cast<std::size_t>(i)]) {
        gray_raw[static_cast<std::size_t>(i)] = 1;
      }
      if (lu >= 95 && lu < 150 && sat < 12 && !black_raw[static_cast<std::size_t>(i)]) {
        win_raw[static_cast<std::size_t>(i)] = 1;
      }
    }
  }

  const std::vector<std::uint8_t> black = keep_large_cc(black_raw, w, h, 50);
  int bx0 = w;
  int by0 = h;
  int bx1 = -1;
  int by1 = -1;
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      if (!black[static_cast<std::size_t>(y * w + x)]) continue;
      bx0 = std::min(bx0, x);
      by0 = std::min(by0, y);
      bx1 = std::max(bx1, x);
      by1 = std::max(by1, y);
    }
  }
  if (bx1 < bx0) {
    out.error = "no structural walls detected";
    return out;
  }

  std::vector<Bar> shear_bars = extract_bars(black, w, h, 10, 4, 50, 0.65);
  if (shear_bars.empty()) {
    out.error = "no structural wall bars";
    return out;
  }

  std::vector<int> thicks;
  thicks.reserve(shear_bars.size());
  for (const Bar& b : shear_bars) {
    if (b.thickness >= 6 && b.thickness <= 20) thicks.push_back(b.thickness);
  }
  if (thicks.empty()) {
    for (const Bar& b : shear_bars) thicks.push_back(b.thickness);
  }
  std::sort(thicks.begin(), thicks.end());
  const int median_th = thicks[thicks.size() / 2];
  double mm_per_px = options.structural_thickness_mm / std::max(1, median_th);
  mm_per_px = std::max(12.0, std::min(28.0, mm_per_px));
  out.mm_per_px = mm_per_px;

  // 阳台 / 飘窗 / 落地窗 grey sits outside the black shear bbox. Cropping to
  // bx1+8 dropped the entire glass perimeter (gold sample: +57px east, +34px
  // south). Keep ~1.7 m of outset so thin envelope strokes become walls.
  const int outset = std::max(48, static_cast<int>(std::ceil(1700.0 / mm_per_px)));
  const int gx0 = std::max(0, bx0 - outset);
  const int gy0 = std::max(0, by0 - outset);
  const int gx1 = std::min(w - 1, bx1 + outset);
  const int gy1 = std::min(h - 1, by1 + outset);
  for (int y = 0; y < h; ++y) {
    for (int x = 0; x < w; ++x) {
      if (x < gx0 || x > gx1 || y < gy0 || y > gy1) {
        gray_raw[static_cast<std::size_t>(y * w + x)] = 0;
        win_raw[static_cast<std::size_t>(y * w + x)] = 0;
      }
    }
  }

  std::vector<Bar> gray_bars = extract_bars(gray_raw, w, h, 20, 3, 14, 0.65);
  std::vector<std::uint8_t> env_mask(static_cast<std::size_t>(w * h), 0);
  for (int y = gy0; y <= gy1; ++y) {
    for (int x = gx0; x <= gx1; ++x) {
      const int i = y * w + x;
      if (!gray_raw[static_cast<std::size_t>(i)] && !win_raw[static_cast<std::size_t>(i)]) continue;
      const bool on_ring = x <= bx0 + outset || x >= bx1 - outset || y <= by0 + outset ||
                           y >= by1 - outset;
      if (on_ring) env_mask[static_cast<std::size_t>(i)] = 1;
    }
  }
  std::vector<Bar> env_stroke_bars = extract_bars(env_mask, w, h, 24, 1, 14, 0.5);
  std::vector<Bar> masonry_bars;
  std::vector<Bar> envelope_windows;
  masonry_bars.reserve(gray_bars.size() + env_stroke_bars.size());
  for (const Bar& g : gray_bars) {
    bool on_black = false;
    for (const Bar& s : shear_bars) {
      if (overlap_frac(g, s) > 0.45) {
        on_black = true;
        break;
      }
    }
    if (on_black) continue;
    masonry_bars.push_back(g);
  }
  for (const Bar& g : env_stroke_bars) {
    bool on_black = false;
    for (const Bar& s : shear_bars) {
      if (overlap_frac(g, s) > 0.5) {
        on_black = true;
        break;
      }
    }
    if (on_black) continue;
    masonry_bars.push_back(g);
  }

  std::vector<Bar> thin = extract_bars(win_raw, w, h, 24, 1, 3, 0.5);
  std::vector<Bar> env_thin;
  for (const Bar& t : thin) {
    if (near_envelope(t, bx0, by0, bx1, by1, outset)) env_thin.push_back(t);
  }
  std::vector<char> used(env_thin.size(), 0);
  for (std::size_t i = 0; i < env_thin.size(); ++i) {
    if (used[i]) continue;
    for (std::size_t j = i + 1; j < env_thin.size(); ++j) {
      if (used[j] || env_thin[i].ori != env_thin[j].ori) continue;
      if (env_thin[i].ori == 'H') {
        const double dy = std::abs(0.5 * (env_thin[i].y0 + env_thin[i].y1) -
                                   0.5 * (env_thin[j].y0 + env_thin[j].y1));
        const int ox0 = std::max(env_thin[i].x0, env_thin[j].x0);
        const int ox1 = std::min(env_thin[i].x1, env_thin[j].x1);
        if (dy >= 4 && dy <= 16 && ox1 - ox0 >= 20) {
          Bar win;
          win.ori = 'H';
          win.x0 = ox0;
          win.x1 = ox1;
          win.y0 = std::min(env_thin[i].y0, env_thin[j].y0);
          win.y1 = std::max(env_thin[i].y1, env_thin[j].y1);
          win.length = ox1 - ox0 + 1;
          win.thickness = win.y1 - win.y0 + 1;
          envelope_windows.push_back(win);
          masonry_bars.push_back(win);
          used[i] = 1;
          used[j] = 1;
          break;
        }
      } else {
        const double dx = std::abs(0.5 * (env_thin[i].x0 + env_thin[i].x1) -
                                   0.5 * (env_thin[j].x0 + env_thin[j].x1));
        const int oy0 = std::max(env_thin[i].y0, env_thin[j].y0);
        const int oy1 = std::min(env_thin[i].y1, env_thin[j].y1);
        if (dx >= 4 && dx <= 16 && oy1 - oy0 >= 20) {
          Bar win;
          win.ori = 'V';
          win.x0 = std::min(env_thin[i].x0, env_thin[j].x0);
          win.x1 = std::max(env_thin[i].x1, env_thin[j].x1);
          win.y0 = oy0;
          win.y1 = oy1;
          win.length = oy1 - oy0 + 1;
          win.thickness = win.x1 - win.x0 + 1;
          envelope_windows.push_back(win);
          masonry_bars.push_back(win);
          used[i] = 1;
          used[j] = 1;
          break;
        }
      }
    }
  }
  for (std::size_t i = 0; i < env_thin.size(); ++i) {
    if (used[i]) continue;
    masonry_bars.push_back(env_thin[i]);
  }

  const double origin_x = static_cast<double>(bx0);
  const double origin_y = static_cast<double>(by1);
  auto mm_x = [&](double pxv) { return (pxv - origin_x) * mm_per_px; };
  auto mm_y = [&](double pyv) { return (origin_y - pyv) * mm_per_px; };

  std::vector<RasterSeg> pending;
  auto emit_seg = [&](const Bar& b, domain::WallKind kind) {
    RasterSeg s;
    s.kind = kind;
    s.thickness_mm = std::max(80.0, static_cast<double>(b.thickness) * mm_per_px);
    if (kind == domain::WallKind::ShearWall) {
      s.thickness_mm = std::max(s.thickness_mm, options.structural_thickness_mm * 0.8);
    }
    if (b.ori == 'H') {
      const double y = mm_y(0.5 * (b.y0 + b.y1));
      s.x0 = mm_x(b.x0);
      s.x1 = mm_x(b.x1);
      s.y0 = s.y1 = y;
    } else {
      const double x = mm_x(0.5 * (b.x0 + b.x1));
      s.x0 = s.x1 = x;
      s.y0 = mm_y(b.y1);
      s.y1 = mm_y(b.y0);
    }
    if (std::hypot(s.x1 - s.x0, s.y1 - s.y0) < 40.0) return;
    pending.push_back(s);
  };

  int si = 0;
  for (const Bar& b : shear_bars) {
    emit_seg(b, domain::WallKind::ShearWall);
    const int short_side = std::min(b.length, b.thickness);
    const int long_side = std::max(b.length, b.thickness);
    if (long_side <= short_side * 2 + 4 && short_side >= 10) {
      ports::DetectedColumn col;
      col.id = make_id("col", static_cast<int>(out.columns.size()));
      col.center_x = mm_x(0.5 * (b.x0 + b.x1));
      col.center_y = mm_y(0.5 * (b.y0 + b.y1));
      col.width_mm = std::abs(mm_x(b.x1) - mm_x(b.x0));
      col.depth_mm = std::abs(mm_y(b.y0) - mm_y(b.y1));
      out.columns.push_back(std::move(col));
    }
  }
  int mi = 0;
  for (const Bar& b : masonry_bars) {
    emit_seg(b, domain::WallKind::Masonry);
  }

  pending = merge_collinear_segments(pending, 120.0, 400.0);
  pending = snap_endpoints(pending, 120.0);
  pending = join_t_junctions(pending, 160.0);
  pending = close_exterior_loop(pending, 120.0, 3600.0);
  pending = join_t_junctions(pending, 160.0);
  pending = merge_collinear_segments(pending, 120.0, 400.0);
  pending = snap_endpoints(pending, 120.0);
  const auto bays = detect_bay_bumps(pending);
  si = 0;
  mi = 0;
  for (auto& s : pending) {
    if (s.kind == domain::WallKind::ShearWall) s.id = make_id("wall_s", si++);
    else s.id = make_id("wall_m", mi++);
    auto wall = seg_to_detected_wall(s);
    wall.height_mm = options.wall_height_mm;
    out.walls.push_back(std::move(wall));
  }

  auto emit_opening_from_bar = [&](const Bar& b, domain::OpeningKind kind, const std::string& id) {
    ports::DetectedOpening op;
    op.id = id;
    op.kind = kind;
    op.center_x = mm_x(0.5 * (b.x0 + b.x1));
    op.center_y = mm_y(0.5 * (b.y0 + b.y1));
    if (b.ori == 'H') {
      op.width_mm = std::abs(mm_x(b.x1) - mm_x(b.x0));
      op.along_x = 1;
      op.along_y = 0;
    } else {
      op.width_mm = std::abs(mm_y(b.y0) - mm_y(b.y1));
      op.along_x = 0;
      op.along_y = 1;
    }
    if (kind == domain::OpeningKind::Door) {
      op.width_mm = std::max(700.0, std::min(1800.0, op.width_mm));
      op.height_mm = options.door_height_mm;
      op.sill_mm = 0;
    } else {
      op.width_mm = std::max(600.0, std::min(3200.0, op.width_mm));
      bool on_bay = false;
      for (const auto& bump : bays) {
        if (point_on_bay(bump, op.center_x, op.center_y, 280.0)) {
          on_bay = true;
          break;
        }
      }
      if (on_bay) {
        op.height_mm = std::max(options.window_height_mm, options.wall_height_mm * 0.72);
        op.sill_mm = 400.0;
      } else if (op.width_mm >= 1500.0) {
        op.sill_mm = 0;
        op.height_mm = std::max(2300.0, options.wall_height_mm - 80.0);
      } else {
        op.height_mm = options.window_height_mm;
        op.sill_mm = options.window_sill_mm;
      }
      op.subtype =
          classify_window_subtype(op.sill_mm, op.height_mm, options.wall_height_mm, on_bay);
    }
    out.openings.push_back(std::move(op));
  };

  int wi = 0;
  for (const Bar& b : envelope_windows) {
    emit_opening_from_bar(b, domain::OpeningKind::Window, make_id("op_w", wi++));
  }

  std::vector<Centerline> lines = to_centerlines(shear_bars, 'S');
  {
    auto more = to_centerlines(masonry_bars, 'M');
    lines.insert(lines.end(), more.begin(), more.end());
  }

  auto gap_on_envelope = [&](const Centerline& a, const Centerline& b) {
    const double mid = 0.5 * (a.a1 + b.a0);
    if (a.ori == 'H') {
      const int y = static_cast<int>(std::lround(a.pos));
      return std::abs(y - by0) <= 22 || std::abs(y - by1) <= 28;
    }
    const int x = static_cast<int>(std::lround(a.pos));
    (void)mid;
    (void)b;
    return std::abs(x - bx0) <= 22 || std::abs(x - bx1) <= 22;
  };

  int di = 0;
  const double door_min = 550.0;
  const double door_max = 1900.0;
  const double win_gap_min = 700.0;
  for (char ori : {'H', 'V'}) {
    std::vector<Centerline> group;
    for (const Centerline& c : lines) {
      if (c.ori == ori) group.push_back(c);
    }
    std::sort(group.begin(), group.end(), [](const Centerline& a, const Centerline& b) {
      if (std::abs(a.pos - b.pos) > 2.5) return a.pos < b.pos;
      return a.a0 < b.a0;
    });
    for (std::size_t i = 0; i + 1 < group.size(); ++i) {
      Centerline a = group[i];
      for (std::size_t j = i + 1; j < group.size(); ++j) {
        Centerline b = group[j];
        if (std::abs(a.pos - b.pos) > std::max(3.0, 0.6 * 0.5 * (a.thick + b.thick))) break;
        if (b.a0 < a.a1 - 2) continue;
        const double gap_px = b.a0 - a.a1;
        const double gap_mm = gap_px * mm_per_px;
        if (gap_px < 8) continue;
        const bool exterior = gap_on_envelope(a, b);
        Bar hole;
        if (ori == 'H') {
          hole.ori = 'H';
          hole.x0 = static_cast<int>(std::lround(a.a1));
          hole.x1 = static_cast<int>(std::lround(b.a0));
          hole.y0 = static_cast<int>(std::lround(a.pos));
          hole.y1 = hole.y0;
          hole.length = hole.x1 - hole.x0;
          hole.thickness = 2;
        } else {
          hole.ori = 'V';
          hole.x0 = static_cast<int>(std::lround(a.pos));
          hole.x1 = hole.x0;
          hole.y0 = static_cast<int>(std::lround(a.a1));
          hole.y1 = static_cast<int>(std::lround(b.a0));
          hole.length = hole.y1 - hole.y0;
          hole.thickness = 2;
        }
        if (exterior && gap_mm >= win_gap_min && gap_mm <= 4200.0) {
          emit_opening_from_bar(hole, domain::OpeningKind::Window, make_id("op_w", wi++));
        } else if (!exterior && gap_mm >= door_min && gap_mm <= door_max) {
          emit_opening_from_bar(hole, domain::OpeningKind::Door, make_id("op_d", di++));
        }
        break;
      }
    }
  }

  auto rebuild_walls = [&]() {
    si = 0;
    mi = 0;
    out.walls.clear();
    for (auto& s : pending) {
      if (s.kind == domain::WallKind::ShearWall) s.id = make_id("wall_s", si++);
      else s.id = make_id("wall_m", mi++);
      auto wall = seg_to_detected_wall(s);
      wall.height_mm = options.wall_height_mm;
      out.walls.push_back(std::move(wall));
    }
  };

  for (const auto& op : out.openings) {
    double best = 1e18;
    for (const auto& w : out.walls) {
      double t = 0;
      best = std::min(best, dist_point_seg(op.center_x, op.center_y, w.start_x, w.start_y, w.end_x,
                                           w.end_y, &t));
    }
    if (best <= 420.0) continue;
    RasterSeg host;
    host.kind = op.kind == domain::OpeningKind::Window ? domain::WallKind::Masonry
                                                       : domain::WallKind::ShearWall;
    host.thickness_mm = op.kind == domain::OpeningKind::Window ? 120.0 : 200.0;
    double ax = op.along_x;
    double ay = op.along_y;
    const double alen = std::hypot(ax, ay);
    if (alen < 1e-6) {
      ax = 1;
      ay = 0;
    } else {
      ax /= alen;
      ay /= alen;
    }
    const double half = 0.5 * std::max(op.width_mm, 800.0) + 80.0;
    host.x0 = op.center_x - ax * half;
    host.y0 = op.center_y - ay * half;
    host.x1 = op.center_x + ax * half;
    host.y1 = op.center_y + ay * half;
    host = extend_segment_to_hits(host, pending, 3600.0, 120.0);
    pending.push_back(host);
  }
  {
    std::vector<RasterCoverSpan> covers;
    covers.reserve(out.openings.size());
    for (const auto& op : out.openings) {
      RasterCoverSpan c;
      c.x0 = op.center_x - 0.5 * op.width_mm * op.along_x;
      c.y0 = op.center_y - 0.5 * op.width_mm * op.along_y;
      c.x1 = op.center_x + 0.5 * op.width_mm * op.along_x;
      c.y1 = op.center_y + 0.5 * op.width_mm * op.along_y;
      covers.push_back(c);
    }
    pending = seal_outer_envelope(pending, covers, 120.0, 3600.0);
    pending = join_t_junctions(pending, 160.0);
    rebuild_walls();
  }

  double core_minx = 1e18, core_miny = 1e18, core_maxx = -1e18, core_maxy = -1e18;
  int longs = 0;
  for (const auto& w : out.walls) {
    const double len = std::hypot(w.end_x - w.start_x, w.end_y - w.start_y);
    if (len < 2200.0) continue;
    ++longs;
    core_minx = std::min({core_minx, w.start_x, w.end_x});
    core_miny = std::min({core_miny, w.start_y, w.end_y});
    core_maxx = std::max({core_maxx, w.start_x, w.end_x});
    core_maxy = std::max({core_maxy, w.start_y, w.end_y});
  }
  if (longs >= 2) {
    for (auto& op : out.openings) {
      if (op.kind != domain::OpeningKind::Window) continue;
      if (op.subtype == domain::WindowSubtype::Bay) continue;
      const bool outside = op.center_x < core_minx - 120 || op.center_x > core_maxx + 120 ||
                           op.center_y < core_miny - 120 || op.center_y > core_maxy + 120;
      if (!outside) continue;
      op.subtype = domain::WindowSubtype::Bay;
      if (op.sill_mm > 80 && op.height_mm < options.wall_height_mm * 0.8) {
        op.sill_mm = 400;
      }
    }
  }

  fill_vision_counts(out, &out.shear_count, &out.masonry_count, nullptr, nullptr);
  double min_x = 1e18;
  double min_y = 1e18;
  for (const auto& wall : out.walls) {
    min_x = std::min({min_x, wall.start_x, wall.end_x});
    min_y = std::min({min_y, wall.start_y, wall.end_y});
  }
  for (const auto& op : out.openings) {
    min_x = std::min(min_x, op.center_x);
    min_y = std::min(min_y, op.center_y);
  }
  if (std::isfinite(min_x) && std::isfinite(min_y) && (min_x != 0.0 || min_y != 0.0) &&
      min_x < 1e17) {
    for (auto& wall : out.walls) {
      wall.start_x -= min_x;
      wall.end_x -= min_x;
      wall.start_y -= min_y;
      wall.end_y -= min_y;
    }
    for (auto& op : out.openings) {
      op.center_x -= min_x;
      op.center_y -= min_y;
    }
    for (auto& col : out.columns) {
      col.center_x -= min_x;
      col.center_y -= min_y;
    }
  }
  out.ok = !out.walls.empty();
  if (!out.ok) out.error = "no walls from raster";
  out.room_name = "户型";
  return out;
}

void fill_vision_counts(const ports::VisionResult& detected, int* shear, int* masonry, int* doors,
                        int* windows) {
  int s = 0;
  int m = 0;
  int d = 0;
  int w = 0;
  for (const auto& wall : detected.walls) {
    if (wall.kind == domain::WallKind::ShearWall) ++s;
    else ++m;
  }
  for (const auto& op : detected.openings) {
    if (op.kind == domain::OpeningKind::Window) ++w;
    else ++d;
  }
  if (shear) *shear = s;
  if (masonry) *masonry = m;
  if (doors) *doors = d;
  if (windows) *windows = w;
}

int apply_vision_result(domain::FloorPlanDocument& doc, const ports::VisionResult& detected,
                        std::string* error) {
  if (!detected.ok) {
    if (error) *error = detected.error.empty() ? "vision failed" : detected.error;
    return 1;
  }
  if (doc.storeys().empty()) {
    if (error) *error = "no storey";
    return 1;
  }
  const std::string storey = doc.storeys()[0].id();
  struct Host {
    std::string id;
    double x0 = 0;
    double y0 = 0;
    double x1 = 0;
    double y1 = 0;
    double length = 0;
    double thickness = 0;
    std::vector<std::pair<double, double>> occupied;
  };
  std::vector<Host> hosts;
  for (const auto& wall : detected.walls) {
    domain::AddWallProps props;
    props.storey_id = storey;
    props.id = wall.id;
    props.start = domain::PointMm::of(wall.start_x, wall.start_y);
    props.end = domain::PointMm::of(wall.end_x, wall.end_y);
    props.thickness = domain::LengthMm::of(std::max(1.0, wall.thickness_mm));
    props.height = domain::LengthMm::of(std::max(1.0, wall.height_mm));
    props.kind = wall.kind;
    try {
      doc.add_wall(std::move(props));
    } catch (const std::exception& ex) {
      if (error) *error = ex.what();
      return 1;
    }
    Host host;
    host.id = wall.id;
    host.x0 = wall.start_x;
    host.y0 = wall.start_y;
    host.x1 = wall.end_x;
    host.y1 = wall.end_y;
    host.length = std::hypot(wall.end_x - wall.start_x, wall.end_y - wall.start_y);
    host.thickness = wall.thickness_mm;
    if (host.length > 1.0) hosts.push_back(std::move(host));
  }

  int added = 0;
  int syn = 0;
  for (const auto& op : detected.openings) {
    int best = -1;
    double best_dist = 1e9;
    double best_t = 0;
    for (std::size_t i = 0; i < hosts.size(); ++i) {
      double t = 0;
      const double d =
          dist_point_seg(op.center_x, op.center_y, hosts[i].x0, hosts[i].y0, hosts[i].x1,
                         hosts[i].y1, &t);
      if (d < best_dist) {
        best_dist = d;
        best = static_cast<int>(i);
        best_t = t;
      }
    }
    const double snap = (best >= 0) ? std::max(hosts[static_cast<std::size_t>(best)].thickness * 2.2, 420.0)
                                    : 420.0;
    if (best < 0 || best_dist > snap) {
      double ax = op.along_x;
      double ay = op.along_y;
      const double alen = std::hypot(ax, ay);
      if (alen < 1e-6) {
        ax = 1;
        ay = 0;
      } else {
        ax /= alen;
        ay /= alen;
      }
      double width = std::max(400.0, op.width_mm);
      const double pad = 80.0;
      const double half = 0.5 * width + pad;
      Host host;
      host.id = "wall_open_" + std::to_string(syn++);
      host.x0 = op.center_x - ax * half;
      host.y0 = op.center_y - ay * half;
      host.x1 = op.center_x + ax * half;
      host.y1 = op.center_y + ay * half;
      host.length = std::hypot(host.x1 - host.x0, host.y1 - host.y0);
      host.thickness = op.kind == domain::OpeningKind::Window ? 120.0 : 200.0;
      domain::AddWallProps props;
      props.storey_id = storey;
      props.id = host.id;
      props.start = domain::PointMm::of(host.x0, host.y0);
      props.end = domain::PointMm::of(host.x1, host.y1);
      props.thickness = domain::LengthMm::of(host.thickness);
      props.height = domain::LengthMm::of(2800);
      props.kind = domain::WallKind::Masonry;
      try {
        doc.add_wall(std::move(props));
      } catch (const std::exception&) {
        continue;
      }
      hosts.push_back(host);
      best = static_cast<int>(hosts.size()) - 1;
      best_t = 0.5;
    }
    Host& host = hosts[static_cast<std::size_t>(best)];
    double width = std::max(400.0, op.width_mm);
    if (width > host.length - 40.0) width = host.length - 40.0;
    if (width < 350.0) continue;
    double offset = best_t * host.length - 0.5 * width;
    offset = std::max(0.0, std::min(host.length - width, offset));
    bool clash = false;
    for (const auto& span : host.occupied) {
      if (!(offset + width <= span.first + 1.0 || span.second <= offset + 1.0)) {
        clash = true;
        break;
      }
    }
    if (clash) continue;
    double height = op.height_mm;
    double sill = op.sill_mm;
    const double wall_h = 2800.0;
    if (sill + height > wall_h) {
      if (op.kind == domain::OpeningKind::Window) {
        sill = 900.0;
        height = std::min(height, wall_h - sill);
      } else {
        sill = 0;
        height = std::min(height, wall_h);
      }
    }
    domain::AddOpeningProps props;
    props.storey_id = storey;
    props.wall_id = host.id;
    props.id = op.id;
    props.kind = op.kind;
    props.width = domain::LengthMm::of(width);
    props.height = domain::LengthMm::of(height);
    props.offset_along_wall = domain::LengthMm::of(offset);
    props.sill_height = domain::LengthMm::of(sill);
    props.subtype = op.subtype;
    try {
      doc.add_opening(std::move(props));
      host.occupied.emplace_back(offset, offset + width);
      ++added;
    } catch (const std::exception&) {
      continue;
    }
  }
  (void)added;

  if (!doc.storeys().empty()) {
    const std::string sid = doc.storeys()[0].id();
    struct Geom {
      std::string id;
      double x0 = 0;
      double y0 = 0;
      double x1 = 0;
      double y1 = 0;
    };
    std::vector<Geom> geoms;
    double min_x = 0;
    double min_y = 0;
    for (const auto& wall : doc.storeys()[0].walls()) {
      geoms.push_back(Geom{wall.id(), wall.start().x(), wall.start().y(), wall.end().x(),
                           wall.end().y()});
      min_x = std::min({min_x, wall.start().x(), wall.end().x()});
      min_y = std::min({min_y, wall.start().y(), wall.end().y()});
    }
    if (min_x < -0.5 || min_y < -0.5) {
      const double dx = min_x < 0 ? -min_x : 0;
      const double dy = min_y < 0 ? -min_y : 0;
      for (const Geom& g : geoms) {
        try {
          doc.move_wall(sid, g.id, domain::PointMm::of(g.x0 + dx, g.y0 + dy),
                        domain::PointMm::of(g.x1 + dx, g.y1 + dy));
        } catch (const std::exception&) {
          continue;
        }
      }
    }
  }
  return 0;
}

ports::VisionResult RasterVisionAdapter::detect_walls(const ports::VisionRequest& request) {
  ports::VisionResult out;
  out.adapter_id = "raster";
  RasterImage image;
  std::string err;
  if (!load_raster_image(request.image_uri, request.image_bytes, &image, &err)) {
    out.ok = false;
    out.error = err.empty() ? "image not found" : err;
    return out;
  }
  return analyze_floor_plan_raster(image);
}

}  // namespace toporoom::adapters
