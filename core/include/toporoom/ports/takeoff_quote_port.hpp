#pragma once

#include <string>

#include "toporoom/ports/p1_status.hpp"

namespace toporoom::ports {

// FR-107 placeholder: takeoff / auto quote. No pricing strategy in P0.
class TakeoffQuotePort {
 public:
  virtual ~TakeoffQuotePort() = default;
  virtual P1Status quote_document(const std::string& document_id,
                                  std::string& quote_json) = 0;
};

}  // namespace toporoom::ports
