#pragma once

#include <string>
#include <unordered_map>

#include "toporoom/ports/document_store_port.hpp"

namespace toporoom::adapters {

class InMemoryDocumentStore : public ports::DocumentStorePort {
 public:
  std::optional<domain::SceneIR> load(const std::string& document_id) override {
    auto it = docs_.find(document_id);
    if (it == docs_.end()) return std::nullopt;
    return it->second;
  }

  void save(const domain::SceneIR& document) override { docs_[document.id] = document; }

 private:
  std::unordered_map<std::string, domain::SceneIR> docs_;
};

}  // namespace toporoom::adapters
