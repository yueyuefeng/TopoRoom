#include <fstream>
#include <iostream>
#include <string>

#include "toporoom/adapters/export_glb.hpp"
#include "toporoom/adapters/manifold_geometry_port.hpp"
#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/ports/geometry_port.hpp"

int main(int argc, char** argv) {
  const char* output = argc > 1 ? argv[1] : "rect-room-door-laser.glb";
  const auto scene = toporoom::adapters::load_scene_ir_file(
      std::string(TOPOROOM_FIXTURE_DIR) + "/rect-room-door-laser.sceneir.json");
  toporoom::adapters::ManifoldGeometryPort geometry;
  toporoom::ports::BuildRequest request;
  request.semantics = toporoom::ports::semantics_from_scene_ir(scene);
  const auto rebuilt = geometry.rebuild(request);
  if (!rebuilt.ok) {
    std::cerr << "rebuild failed: " << rebuilt.fault.message << '\n';
    return 1;
  }
  const auto glb = toporoom::adapters::export_glb(scene, rebuilt.meshes);
  std::ofstream out(output, std::ios::binary);
  out.write(reinterpret_cast<const char*>(glb.data()), static_cast<std::streamsize>(glb.size()));
  if (!out) {
    std::cerr << "failed to write " << output << '\n';
    return 1;
  }
  return 0;
}
