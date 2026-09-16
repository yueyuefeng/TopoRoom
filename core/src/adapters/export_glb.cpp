#include "toporoom/adapters/export_glb.hpp"

#include <algorithm>
#include <array>
#include <cstring>
#include <unordered_map>
#include <vector>

#include <nlohmann/json.hpp>

namespace toporoom::adapters {
namespace {

void append_u32(std::vector<std::uint8_t>& out, std::uint32_t value) {
  out.push_back(static_cast<std::uint8_t>(value));
  out.push_back(static_cast<std::uint8_t>(value >> 8));
  out.push_back(static_cast<std::uint8_t>(value >> 16));
  out.push_back(static_cast<std::uint8_t>(value >> 24));
}

void append_f32(std::vector<std::uint8_t>& out, float value) {
  std::uint32_t bits = 0;
  std::memcpy(&bits, &value, sizeof(bits));
  append_u32(out, bits);
}

void pad4(std::vector<std::uint8_t>& bytes, std::uint8_t fill) {
  while (bytes.size() % 4 != 0) bytes.push_back(fill);
}

struct PackedMesh {
  std::string node_hint;
  std::vector<float> positions_m;
  std::vector<std::uint32_t> indices;
  std::array<float, 3> min{1e30f, 1e30f, 1e30f};
  std::array<float, 3> max{-1e30f, -1e30f, -1e30f};
};

PackedMesh pack_solid(const ports::MeshSolid& solid) {
  PackedMesh packed;
  packed.node_hint = solid.node_hint;
  packed.positions_m.reserve(solid.vertices_mm.size());
  for (std::size_t i = 0; i + 2 < solid.vertices_mm.size(); i += 3) {
    const float x = static_cast<float>(solid.vertices_mm[i] * kMmToM);
    const float y = static_cast<float>(solid.vertices_mm[i + 1] * kMmToM);
    const float z = static_cast<float>(solid.vertices_mm[i + 2] * kMmToM);
    packed.positions_m.push_back(x);
    packed.positions_m.push_back(y);
    packed.positions_m.push_back(z);
    packed.min[0] = std::min(packed.min[0], x);
    packed.min[1] = std::min(packed.min[1], y);
    packed.min[2] = std::min(packed.min[2], z);
    packed.max[0] = std::max(packed.max[0], x);
    packed.max[1] = std::max(packed.max[1], y);
    packed.max[2] = std::max(packed.max[2], z);
  }
  packed.indices.reserve(solid.indices.size());
  for (int index : solid.indices) {
    if (index >= 0) packed.indices.push_back(static_cast<std::uint32_t>(index));
  }
  return packed;
}

}  // namespace

std::vector<std::uint8_t> export_glb(const domain::SceneIR& scene,
                                     const ports::MeshProjection& meshes) {
  const SceneGraph graph = export_scene_graph(scene, meshes);

  std::vector<PackedMesh> packed;
  std::unordered_map<std::string, int> mesh_index_by_hint;
  for (const auto& solid : meshes.solids) {
    if (solid.vertices_mm.size() < 9) continue;
    mesh_index_by_hint[solid.node_hint] = static_cast<int>(packed.size());
    packed.push_back(pack_solid(solid));
  }

  std::vector<std::uint8_t> bin;
  nlohmann::json buffer_views = nlohmann::json::array();
  nlohmann::json accessors = nlohmann::json::array();
  nlohmann::json gltf_meshes = nlohmann::json::array();

  for (const auto& mesh : packed) {
    pad4(bin, 0);
    const int pos_view = static_cast<int>(buffer_views.size());
    const std::size_t pos_offset = bin.size();
    for (float value : mesh.positions_m) append_f32(bin, value);
    buffer_views.push_back({{"buffer", 0},
                            {"byteOffset", static_cast<int>(pos_offset)},
                            {"byteLength", static_cast<int>(mesh.positions_m.size() * 4)},
                            {"target", 34962}});
    const int pos_accessor = static_cast<int>(accessors.size());
    accessors.push_back({{"bufferView", pos_view},
                         {"componentType", 5126},
                         {"count", static_cast<int>(mesh.positions_m.size() / 3)},
                         {"type", "VEC3"},
                         {"min", mesh.min},
                         {"max", mesh.max}});

    nlohmann::json primitive = {{"attributes", {{"POSITION", pos_accessor}}},
                                {"mode", 4}};
    if (!mesh.indices.empty()) {
      pad4(bin, 0);
      const int idx_view = static_cast<int>(buffer_views.size());
      const std::size_t idx_offset = bin.size();
      for (std::uint32_t index : mesh.indices) append_u32(bin, index);
      buffer_views.push_back({{"buffer", 0},
                              {"byteOffset", static_cast<int>(idx_offset)},
                              {"byteLength", static_cast<int>(mesh.indices.size() * 4)},
                              {"target", 34963}});
      const int idx_accessor = static_cast<int>(accessors.size());
      accessors.push_back({{"bufferView", idx_view},
                           {"componentType", 5125},
                           {"count", static_cast<int>(mesh.indices.size())},
                           {"type", "SCALAR"}});
      primitive["indices"] = idx_accessor;
    }
    gltf_meshes.push_back({{"name", mesh.node_hint},
                           {"primitives", nlohmann::json::array({primitive})}});
  }

  std::unordered_map<std::string, int> index_by_name;
  for (int i = 0; i < static_cast<int>(graph.nodes.size()); ++i) {
    index_by_name[graph.nodes[static_cast<std::size_t>(i)].name] = i;
  }

  nlohmann::json nodes = nlohmann::json::array();
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
    // Meshes are in world metres; only storey elevation is a node translation.
    if (node.kind == "storey" && node.translation_meters) {
      gltf_node["translation"] = *node.translation_meters;
      root_nodes.push_back(i);
    }
    const auto mesh_it = mesh_index_by_hint.find(node.name);
    if (mesh_it != mesh_index_by_hint.end()) {
      gltf_node["mesh"] = mesh_it->second;
    }
    nodes.push_back(std::move(gltf_node));
  }

  nlohmann::json gltf = {
      {"asset", {{"version", "2.0"}, {"generator", kCompilerGenerator}}},
      {"scene", 0},
      {"scenes", nlohmann::json::array({{{"nodes", root_nodes}}})},
      {"nodes", nodes}};
  if (!bin.empty()) {
    pad4(bin, 0);
    gltf["buffers"] = nlohmann::json::array({{{"byteLength", static_cast<int>(bin.size())}}});
    gltf["bufferViews"] = buffer_views;
    gltf["accessors"] = accessors;
    gltf["meshes"] = gltf_meshes;
  }

  std::string json = gltf.dump();
  std::vector<std::uint8_t> json_bytes(json.begin(), json.end());
  pad4(json_bytes, static_cast<std::uint8_t>(' '));

  std::vector<std::uint8_t> glb;
  const std::uint32_t json_chunk = static_cast<std::uint32_t>(json_bytes.size());
  const std::uint32_t bin_chunk =
      bin.empty() ? 0u : static_cast<std::uint32_t>(bin.size());
  const std::uint32_t total =
      12u + 8u + json_chunk + (bin.empty() ? 0u : 8u + bin_chunk);
  glb.reserve(total);
  append_u32(glb, 0x46546C67u);  // glTF
  append_u32(glb, 2u);
  append_u32(glb, total);
  append_u32(glb, json_chunk);
  append_u32(glb, 0x4E4F534Au);  // JSON
  glb.insert(glb.end(), json_bytes.begin(), json_bytes.end());
  if (!bin.empty()) {
    append_u32(glb, bin_chunk);
    append_u32(glb, 0x004E4942u);  // BIN\0
    glb.insert(glb.end(), bin.begin(), bin.end());
  }
  return glb;
}

}  // namespace toporoom::adapters
