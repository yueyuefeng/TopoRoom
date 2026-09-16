#pragma once

#include "toporoom/adapters/export_scene_graph.hpp"
#include "toporoom/app/status_gate.hpp"
#include "toporoom/domain/scene_ir.hpp"
#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

struct ExportOutcome {
  bool ok = false;
  adapters::SceneGraph graph;
  std::string gltf_json;
  ports::MeshProjection meshes;
  ports::GeometryFault fault;
};

class ExportAppService {
 public:
  explicit ExportAppService(ports::GeometryPort& geometry) : geometry_(geometry) {}

  ExportOutcome export_scene_graph(const domain::SceneIR& scene);

 private:
  ports::GeometryPort& geometry_;
  StatusGate gate_;
};

}  // namespace toporoom::app
