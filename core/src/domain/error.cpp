#include "toporoom/domain/error.hpp"

namespace toporoom::domain {

DomainError::DomainError(std::string message, std::string code)
    : std::runtime_error(std::move(message)), code_(std::move(code)) {}

}  // namespace toporoom::domain
