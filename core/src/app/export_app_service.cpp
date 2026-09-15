#include "toporoom/app/export_app_service.hpp"

#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

ExportOutcome ExportAppService::export_scene_graph(const domain::SceneIR& scene) {
  ports::BuildRequest request;
  request.document_rev = scene.revision;
  request.rebuild_generation = 1;
  request.dirty = true;
  request.semantics = ports::semantics_from_scene_ir(scene);
  const auto rebuilt = geometry_.rebuild(request);
  ExportOutcome outcome;
  try {
    outcome.meshes = gate_.assert_exportable(rebuilt);
    outcome.graph = adapters::export_scene_graph(scene, outcome.meshes);
    outcome.gltf_json = adapters::export_gltf_json(scene, outcome.meshes);
    outcome.ok = true;
  } catch (const ExportRejectedError& error) {
    outcome.ok = false;
    outcome.fault = error.fault();
  }
  return outcome;
}

}  // namespace toporoom::app
