#pragma once

#include <optional>
#include <string>

#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::adapters {

// Production GeometryPort: CrossSection → Extrude → Boolean(subtract openings).
// Manifold types stay in the .cpp (I2 / NFR-015). Domain never sees them.
class ManifoldGeometryPort : public ports::GeometryPort {
 public:
  ports::RebuildResult rebuild(const ports::BuildRequest& request) override;
  ports::RebuildResult ensure_built(
      int document_rev, std::optional<std::string> storey_id = std::nullopt,
      std::optional<std::string> solid_id = std::nullopt) override;
  ports::GeometryStatus status(std::optional<std::string> solid_id,
                               std::optional<std::string> storey_id) override;
  void clear_cache() override;

 private:
  std::optional<int> cached_rev_;
  ports::RebuildResult cached_;
  ports::GeometryStatus last_status_ = ports::GeometryStatus::Unknown;
};

}  // namespace toporoom::adapters
