#pragma once

#include <string>
#include <string_view>

namespace toporoom::ports {

inline constexpr const char* kNotInP0 = "NotInP0";

// Shared result for P1+ reserved ports (FR-013). Never a P0 Done gate.
struct P1Status {
  bool ok = false;
  std::string code = kNotInP0;
  std::string message;
};

inline P1Status not_in_p0(std::string_view feature) {
  P1Status status;
  status.ok = false;
  status.code = kNotInP0;
  status.message =
      std::string(feature) + " is P1+ (FR-013); not a P0 Done acceptance gate";
  return status;
}

}  // namespace toporoom::ports
