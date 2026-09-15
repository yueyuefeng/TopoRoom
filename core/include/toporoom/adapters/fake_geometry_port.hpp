#pragma once

#include <optional>

#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::adapters {

class FakeGeometryPort : public ports::GeometryPort {
 public:
  void fail_with(ports::GeometryFault fault);
  void succeed();
  const ports::BuildRequest* last_build_request() const;

  ports::RebuildResult rebuild(const ports::BuildRequest& request) override;
  ports::RebuildResult ensure_built(
      int document_rev, std::optional<std::string> storey_id = std::nullopt,
      std::optional<std::string> solid_id = std::nullopt) override;
  ports::GeometryStatus status(std::optional<std::string> solid_id,
                               std::optional<std::string> storey_id) override;
  void clear_cache() override;

 private:
  bool ok_mode_ = true;
  ports::GeometryFault fault_{ports::FaultCode::NotManifold, "synthetic fault", {}};
  std::optional<ports::BuildRequest> last_request_;
  ports::GeometryStatus last_status_ = ports::GeometryStatus::Unknown;
};

ports::MeshProjection project_semantics(const ports::FloorPlanSolidSemantics& semantics);

}  // namespace toporoom::adapters
