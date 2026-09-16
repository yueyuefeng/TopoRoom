#pragma once

#include <optional>
#include <string>

#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::ports {

class DocumentStorePort {
 public:
  virtual ~DocumentStorePort() = default;
  virtual std::optional<domain::SceneIR> load(const std::string& document_id) = 0;
  virtual void save(const domain::SceneIR& document) = 0;
};

}  // namespace toporoom::ports
