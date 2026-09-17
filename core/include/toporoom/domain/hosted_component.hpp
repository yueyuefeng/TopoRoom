#pragma once

#include <string>

#include "toporoom/domain/kinds.hpp"

namespace toporoom::domain {

// HostedComponent: 梁 / 柱 / 烟道. Present in the model; P0 Done does not require any.
struct HostedComponent {
  std::string id;
  HostedKind kind = HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
};

}  // namespace toporoom::domain
