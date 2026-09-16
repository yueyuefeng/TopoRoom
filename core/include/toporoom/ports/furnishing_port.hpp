#pragma once

#include <string>
#include <vector>

#include "toporoom/ports/p1_status.hpp"

namespace toporoom::ports {

// FR-106 placeholder: catalog + place. No Boolean, no PickLayer in P0.
struct FurnishingItem {
  std::string sku;
  std::string name;
};

class FurnishingLibraryPort {
 public:
  virtual ~FurnishingLibraryPort() = default;
  virtual P1Status list_catalog(std::vector<FurnishingItem>& out) = 0;
  virtual P1Status place(const std::string& document_id, const std::string& sku) = 0;
};

}  // namespace toporoom::ports
