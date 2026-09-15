#include "toporoom/adapters/export_scene_graph.hpp"

#include <algorithm>
#include <nlohmann/json.hpp>
#include <unordered_map>

namespace toporoom::adapters {
namespace {

std::array<double, 3> midpoint_meters(const domain::SceneIRPoint& start,
                                      const domain::SceneIRPoint& end) {
  return {((start.x + end.x) / 2.0) * kMmToM, 0.0,
          ((start.y + end.y) / 2.0) * kMmToM};
}

}  // namespace

SceneGraph export_scene_graph(const domain::SceneIR& scene,
                              const ports::MeshProjection& /*meshes*/) {
  SceneGraph graph;
  for (const auto& storey : scene.storeys) {
    SceneGraphNode storey_node;
    storey_node.name = "Storey_" + storey.id;
    storey_node.toporoom_id = storey.id;
    storey_node.kind = "storey";
    storey_node.translation_meters = {0.0, storey.elevation_mm * kMmToM, 0.0};

    std::vector<SceneGraphNode> extra;
    for (const auto& wall : storey.walls) {
      const std::string wall_name = "Wall_" + wall.id;
      storey_node.children.push_back(wall_name);
      SceneGraphNode wall_node;
      wall_node.name = wall_name;
      wall_node.toporoom_id = wall.id;
      wall_node.kind = "wall";
      wall_node.translation_meters = midpoint_meters(wall.start, wall.end);
      for (const auto& opening : wall.openings) {
        const std::string opening_name = "Opening_" + opening.id;
        wall_node.children.push_back(opening_name);
        SceneGraphNode opening_node;
        opening_node.name = opening_name;
        opening_node.toporoom_id = opening.id;
        opening_node.kind = "opening";
        extra.push_back(std::move(opening_node));
      }
      extra.insert(extra.begin(), std::move(wall_node));
    }
    for (const auto& room : storey.rooms) {
      const std::string room_name = "Room_" + room.id;
      storey_node.children.push_back(room_name);
      SceneGraphNode room_node;
      room_node.name = room_name;
      room_node.toporoom_id = room.id;
      room_node.kind = "room";
      extra.push_back(std::move(room_node));
    }
    graph.nodes.push_back(std::move(storey_node));
    graph.nodes.insert(graph.nodes.end(), extra.begin(), extra.end());
  }
  return graph;
}

std::string scene_graph_to_json(const SceneGraph& graph) {
  nlohmann::json nodes = nlohmann::json::array();
  for (const auto& node : graph.nodes) {
    nlohmann::json j = {{"name", node.name},
                        {"extras",
                         {{"toporoomId", node.toporoom_id}, {"kind", node.kind}}},
                        {"children", node.children}};
    if (node.translation_meters) {
      j["translationMeters"] = *node.translation_meters;
    }
    nodes.push_back(std::move(j));
  }
  nlohmann::json root = {{"generator", graph.generator},
                         {"sourceUnits", graph.source_units},
                         {"units", graph.units},
                         {"nodes", nodes}};
  return root.dump();
}

std::string export_gltf_json(const domain::SceneIR& scene,
                             const ports::MeshProjection& meshes) {
  const SceneGraph graph = export_scene_graph(scene, meshes);
  nlohmann::json nodes = nlohmann::json::array();
  std::unordered_map<std::string, int> index_by_name;
  for (int i = 0; i < static_cast<int>(graph.nodes.size()); ++i) {
    index_by_name[graph.nodes[static_cast<std::size_t>(i)].name] = i;
  }

  nlohmann::json root_nodes = nlohmann::json::array();
  for (int i = 0; i < static_cast<int>(graph.nodes.size()); ++i) {
    const auto& node = graph.nodes[static_cast<std::size_t>(i)];
    nlohmann::json gltf_node = {
        {"name", node.name},
        {"extras", {{"toporoomId", node.toporoom_id}, {"kind", node.kind}}}};
    if (!node.children.empty()) {
      nlohmann::json children = nlohmann::json::array();
      for (const auto& child : node.children) {
        children.push_back(index_by_name.at(child));
      }
      gltf_node["children"] = children;
    }
    if (node.translation_meters) {
      gltf_node["translation"] = *node.translation_meters;
    }
    for (const auto& solid : meshes.solids) {
      if (solid.node_hint == node.name && !solid.vertices_mm.empty()) {
        gltf_node["mesh"] = 0;
        break;
      }
    }
    if (node.kind == "storey") {
      root_nodes.push_back(i);
    }
    nodes.push_back(std::move(gltf_node));
  }

  nlohmann::json gltf = {{"asset",
                          {{"version", "2.0"}, {"generator", kCompilerGenerator}}},
                         {"scene", 0},
                         {"scenes", nlohmann::json::array({{{"nodes", root_nodes}}})},
                         {"nodes", nodes}};

  std::vector<double> positions;
  for (const auto& solid : meshes.solids) {
    for (double value : solid.vertices_mm) {
      positions.push_back(value * kMmToM);
    }
  }
  if (!positions.empty()) {
    std::array<double, 3> maxv{-1e300, -1e300, -1e300};
    std::array<double, 3> minv{1e300, 1e300, 1e300};
    for (std::size_t i = 0; i + 2 < positions.size(); i += 3) {
      for (int c = 0; c < 3; ++c) {
        maxv[static_cast<std::size_t>(c)] =
            std::max(maxv[static_cast<std::size_t>(c)], positions[i + static_cast<std::size_t>(c)]);
        minv[static_cast<std::size_t>(c)] =
            std::min(minv[static_cast<std::size_t>(c)], positions[i + static_cast<std::size_t>(c)]);
      }
    }
    gltf["meshes"] = nlohmann::json::array(
        {{{"primitives", nlohmann::json::array({{{"attributes", {{"POSITION", 0}}}}})}}});
    gltf["accessors"] = nlohmann::json::array({{{"bufferView", 0},
                                                {"componentType", 5126},
                                                {"count", static_cast<int>(positions.size() / 3)},
                                                {"type", "VEC3"},
                                                {"max", maxv},
                                                {"min", minv}}});
  }
  return gltf.dump();
}

}  // namespace toporoom::adapters
