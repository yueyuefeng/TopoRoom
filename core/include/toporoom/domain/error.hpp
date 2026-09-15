#pragma once

#include <stdexcept>
#include <string>
#include <utility>

namespace toporoom::domain {

class DomainError : public std::runtime_error {
 public:
  DomainError(std::string message, std::string code = "DOMAIN_ERROR");

  const std::string& code() const noexcept { return code_; }

 private:
  std::string code_;
};

}  // namespace toporoom::domain
