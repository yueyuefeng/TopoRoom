#pragma once

#include "toporoom/ports/floor_plan_vision_port.hpp"

namespace toporoom::adapters {

// Deterministic walls + WallKind for CI / Godot. Ignores pixels; keyed off any
// image URI (including the bundled fake floor-plan fixture).
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
