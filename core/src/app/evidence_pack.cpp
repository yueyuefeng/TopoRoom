#include "toporoom/app/evidence_pack.hpp"

#include <algorithm>

namespace toporoom::app {

void EvidencePack::attach(EvidenceItem item) { items_.push_back(std::move(item)); }

bool EvidencePack::detach(const std::string& id) {
  const auto before = items_.size();
  items_.erase(std::remove_if(items_.begin(), items_.end(),
                              [&](const EvidenceItem& item) { return item.id == id; }),
               items_.end());
  return items_.size() != before;
}

void EvidencePack::detach_all() { items_.clear(); }

}  // namespace toporoom::app
