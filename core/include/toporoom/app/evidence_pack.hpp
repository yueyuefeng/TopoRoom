#pragma once

#include <string>
#include <vector>

namespace toporoom::app {

struct EvidenceItem {
  std::string id;
  std::string kind;
  std::string uri;
};

// Observation sidecar. May be empty; never SceneIR truth (I1 / I5).
class EvidencePack {
 public:
  explicit EvidencePack(std::string document_id) : document_id_(std::move(document_id)) {}

  const std::string& document_id() const noexcept { return document_id_; }
  bool empty() const noexcept { return items_.empty(); }
  const std::vector<EvidenceItem>& items() const noexcept { return items_; }

  void attach(EvidenceItem item);
  bool detach(const std::string& id);
  void detach_all();

 private:
  std::string document_id_;
  std::vector<EvidenceItem> items_;
};

}  // namespace toporoom::app
