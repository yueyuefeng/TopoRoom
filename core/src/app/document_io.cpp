#include "toporoom/app/document_io.hpp"

#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

DocumentNotFoundError::DocumentNotFoundError(const std::string& document_id)
    : std::runtime_error("Document " + document_id + " not found") {}

GeometryRebuildPolicy::GeometryRebuildPolicy(ports::GeometryPort& geometry)
    : geometry_(geometry) {}

ports::RebuildResult GeometryRebuildPolicy::on_semantics_changed(
    const domain::SceneIR& scene) {
  ++generation_;
  ports::BuildRequest request;
  request.document_rev = scene.revision;
  request.rebuild_generation = generation_;
  request.dirty = true;
  request.semantics = ports::semantics_from_scene_ir(scene);
  return geometry_.rebuild(request);
}

domain::FloorPlanDocument load_document(ports::DocumentStorePort& store,
                                        const std::string& document_id) {
  auto scene = store.load(document_id);
  if (!scene) {
    throw DocumentNotFoundError(document_id);
  }
  return domain::FloorPlanDocument::from_scene_ir(*scene);
}

CommandResult commit(ports::DocumentStorePort& store, GeometryRebuildPolicy& rebuild,
                     domain::FloorPlanDocument& document) {
  CommandResult result;
  result.events = document.pull_domain_events();
  result.scene = document.to_scene_ir();
  store.save(result.scene);
  result.rebuild = rebuild.on_semantics_changed(result.scene);
  return result;
}

}  // namespace toporoom::app
