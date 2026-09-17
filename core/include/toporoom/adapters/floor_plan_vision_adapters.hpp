#pragma once

#include "toporoom/ports/floor_plan_vision_port.hpp"

namespace toporoom::adapters {

// Deterministic walls + WallKind for CI / Godot. Requires a readable file when
// image_uri looks like a filesystem path (empty / fixture: URIs still work).
class FakeVisionAdapter : public ports::FloorPlanVisionPort {
 public:
  ports::VisionResult detect_walls(const ports::VisionRequest& request) override;
};

// Future on-device ML. Always returns a not-linked stub result.
class OnDeviceMlVisionAdapter : public ports::FloorPlanVisionPort {
 public:
  ports::VisionResult detect_walls(const ports::VisionRequest& request) override;
};

}  // namespace toporoom::adapters
