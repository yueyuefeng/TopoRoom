#pragma once

#include <cmath>
#include <string>

#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::adapters {

inline int round_mm(double value_mm) { return static_cast<int>(std::lround(value_mm)); }

// ASCII DXF 户型图 (unit plan), not 平面布置图. Millimetres via round_mm().
std::string export_dxf(const domain::SceneIR& scene);

}  // namespace toporoom::adapters
