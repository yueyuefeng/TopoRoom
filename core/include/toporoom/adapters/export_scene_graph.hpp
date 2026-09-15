#pragma once

#include <array>
#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/scene_ir.hpp"
#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::adapters {

inline constexpr const char* kCompilerGenerator = "toporoom-compiler/0.1.0";
inline constexpr double kMmToM = 0.001;

struct SceneGraphNode {
  std::string name;
  std::string toporoom_id;
  std::string kind;
  std::vector<std::string> children;
  std::optional<std::array<double, 3>> translation_meters;
};

struct SceneGraph {
  std::string generator = kCompilerGenerator;
  std::string source_units = "mm";
  std::string units = "m";
  std::vector<SceneGraphNode> nodes;
};

SceneGraph export_scene_graph(const domain::SceneIR& scene,
                              const ports::MeshProjection& meshes);

std::string export_gltf_json(const domain::SceneIR& scene,
                             const ports::MeshProjection& meshes);

std::string scene_graph_to_json(const SceneGraph& graph);

}  // namespace toporoom::adapters
