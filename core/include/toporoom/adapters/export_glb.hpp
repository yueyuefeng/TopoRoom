#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "toporoom/adapters/export_scene_graph.hpp"
#include "toporoom/domain/scene_ir.hpp"
#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::adapters {

// Binary glTF 2.0 (.glb). Positions are converted mm→m only here (kMmToM).
std::vector<std::uint8_t> export_glb(const domain::SceneIR& scene,
                                     const ports::MeshProjection& meshes);

}  // namespace toporoom::adapters
