#pragma once

#include <string>

#include "toporoom/ports/p1_status.hpp"

namespace toporoom::ports {

// FR-108 placeholder: document-level push/pull. No LWW, no auto-upload in P0.
class CloudSyncPort {
 public:
  virtual ~CloudSyncPort() = default;
  virtual P1Status push_document(const std::string& document_id) = 0;
  virtual P1Status pull_document(const std::string& document_id) = 0;
};

}  // namespace toporoom::ports
