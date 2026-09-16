#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::adapters {

// Minimal PDF 1.4 2D floor plan (walls, openings, rounded mm dimensions).
std::vector<std::uint8_t> export_pdf(const domain::SceneIR& scene);

}  // namespace toporoom::adapters
