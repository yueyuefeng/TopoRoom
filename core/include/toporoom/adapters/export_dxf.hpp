#pragma once

#include <cmath>
#include <string>

#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::adapters {

inline int round_mm(double value_mm) { return static_cast<int>(std::lround(value_mm)); }

// ASCII DXF (R12-ish). Geometry stays millimetres with round_mm().
std::string export_dxf(const domain::SceneIR& scene);

}  // namespace toporoom::adapters
