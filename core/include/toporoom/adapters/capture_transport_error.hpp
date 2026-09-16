#pragma once

#include <stdexcept>
#include <string>
#include <utility>

namespace toporoom::adapters {

class CaptureTransportError : public std::runtime_error {
 public:
  enum class Kind { NotConnected, Timeout, Disconnected, Protocol };

  CaptureTransportError(Kind kind, std::string message)
      : std::runtime_error(std::move(message)), kind_(kind) {}

  Kind kind() const noexcept { return kind_; }

 private:
  Kind kind_;
};

}  // namespace toporoom::adapters
