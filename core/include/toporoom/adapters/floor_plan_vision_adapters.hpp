#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "toporoom/ports/floor_plan_vision_port.hpp"

namespace toporoom::domain {
class FloorPlanDocument;
}

namespace toporoom::adapters {

// Deterministic walls + WallKind for CI / `fixture:photo`. Filesystem paths that
// are not readable still fail.
class FakeVisionAdapter : public ports::FloorPlanVisionPort {
 public:
  ports::VisionResult detect_walls(const ports::VisionRequest& request) override;
};

// Raster PNG/JPEG → orthogonal shear/masonry centerlines + heuristic openings.
class RasterVisionAdapter : public ports::FloorPlanVisionPort {
 public:
  ports::VisionResult detect_walls(const ports::VisionRequest& request) override;
};

class OnDeviceMlVisionAdapter : public ports::FloorPlanVisionPort {
 public:
  ports::VisionResult detect_walls(const ports::VisionRequest& request) override;
};

struct RasterAnalyzeOptions {
  double structural_thickness_mm = 200;
  double wall_height_mm = 2800;
  double door_width_mm = 900;
  double door_height_mm = 2100;
  double window_height_mm = 1400;
  double window_sill_mm = 900;
  // User scale calibration (original-image millimetres per pixel). 0 = auto
  // from median 200 mm shear-bar thickness.
  double mm_per_px_override = 0;
};

struct RasterImage {
  int width = 0;
  int height = 0;
  int channels = 0;
  std::vector<unsigned char> rgb;
};

bool load_raster_image(const std::string& path, const std::vector<std::uint8_t>& bytes,
                       RasterImage* out, std::string* error);

ports::VisionResult analyze_floor_plan_raster(const RasterImage& image,
                                              const RasterAnalyzeOptions& options = {});

// Writes walls + openings into an existing document (first storey).
int apply_vision_result(domain::FloorPlanDocument& doc, const ports::VisionResult& detected,
                        std::string* error);

void fill_vision_counts(const ports::VisionResult& detected, int* shear, int* masonry,
                        int* doors, int* windows);

}  // namespace toporoom::adapters
