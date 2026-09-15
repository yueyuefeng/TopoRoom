#pragma once

#include <stdexcept>
#include <string>
#include <vector>

#include "toporoom/domain/events.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/scene_ir.hpp"
#include "toporoom/ports/document_store_port.hpp"
#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

class GeometryRebuildPolicy {
 public:
  explicit GeometryRebuildPolicy(ports::GeometryPort& geometry);
  ports::RebuildResult on_semantics_changed(const domain::SceneIR& scene);

 private:
  ports::GeometryPort& geometry_;
  int generation_ = 0;
};

struct CommandResult {
  domain::SceneIR scene;
  std::vector<domain::DomainEvent> events;
  ports::RebuildResult rebuild;
};

class DocumentNotFoundError : public std::runtime_error {
 public:
  explicit DocumentNotFoundError(const std::string& document_id);
};

domain::FloorPlanDocument load_document(ports::DocumentStorePort& store,
                                        const std::string& document_id);

CommandResult commit(ports::DocumentStorePort& store, GeometryRebuildPolicy& rebuild,
                     domain::FloorPlanDocument& document);

}  // namespace toporoom::app
