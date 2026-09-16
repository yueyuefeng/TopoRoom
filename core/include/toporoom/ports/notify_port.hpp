#pragma once

#include <string>

#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::ports {

class NotifyPort {
 public:
  virtual ~NotifyPort() = default;
  virtual void info(const std::string& message) = 0;
  virtual void warn(const std::string& message) = 0;
  virtual void error(const std::string& message) = 0;
  virtual void geometry_fault(const GeometryFault& fault) = 0;
};

}  // namespace toporoom::ports
