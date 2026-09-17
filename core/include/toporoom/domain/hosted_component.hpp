#pragma once

#include <optional>
#include <string>

#include "toporoom/domain/kinds.hpp"

namespace toporoom::domain {

// HostedComponent: 梁 / 柱 / 烟道. Hosted on a storey, optionally on a wall.
struct HostedComponent {
  std::string id;
  HostedKind kind = HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
  std::optional<std::string> host_wall_id;
};

}  // namespace toporoom::domain
