#pragma once

#include <cmath>
#include <stdexcept>
#include <string>

#include "toporoom/domain/error.hpp"

namespace toporoom::domain {

class LengthMm {
 public:
  static LengthMm of(double value) {
    if (!std::isfinite(value)) {
      throw DomainError("LengthMm must be a finite number of millimetres",
                        "INVALID_LENGTH");
    }
    if (value < 0) {
      throw DomainError("LengthMm must not be negative", "NEGATIVE_LENGTH");
    }
    return LengthMm(value);
  }

  static LengthMm zero() { return LengthMm(0); }

  double value() const noexcept { return value_; }

  bool equals(const LengthMm& other) const noexcept {
    return value_ == other.value_;
  }

  bool operator==(const LengthMm& other) const noexcept { return equals(other); }

 private:
  explicit LengthMm(double value) : value_(value) {}
  double value_;
};

}  // namespace toporoom::domain
