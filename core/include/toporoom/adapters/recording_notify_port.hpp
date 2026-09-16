#pragma once

#include <string>
#include <vector>

#include "toporoom/ports/geometry_port.hpp"
#include "toporoom/ports/notify_port.hpp"

namespace toporoom::adapters {

class RecordingNotifyPort : public ports::NotifyPort {
 public:
  void info(const std::string& message) override { infos.push_back(message); }
  void warn(const std::string& message) override { warns.push_back(message); }
  void error(const std::string& message) override { errors.push_back(message); }
  void geometry_fault(const ports::GeometryFault& fault) override {
    faults.push_back(fault);
  }

  std::vector<std::string> infos;
  std::vector<std::string> warns;
  std::vector<std::string> errors;
  std::vector<ports::GeometryFault> faults;
};

}  // namespace toporoom::adapters
