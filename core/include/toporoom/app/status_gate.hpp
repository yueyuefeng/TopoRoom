#pragma once

#include <stdexcept>
#include <string>

#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

class ExportRejectedError : public std::runtime_error {
 public:
  explicit ExportRejectedError(ports::GeometryFault fault)
      : std::runtime_error("Export rejected: " + std::string(ports::to_string(fault.code)) +
                           " " + fault.message),
        fault_(std::move(fault)) {}

  const ports::GeometryFault& fault() const noexcept { return fault_; }

 private:
  ports::GeometryFault fault_;
};

class StatusGate {
 public:
  ports::MeshProjection assert_exportable(const ports::RebuildResult& result) const {
    if (!result.ok) {
      throw ExportRejectedError(result.fault);
    }
    return result.meshes;
  }
};

}  // namespace toporoom::app
