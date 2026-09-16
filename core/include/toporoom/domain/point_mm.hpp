#pragma once

#include <cmath>

#include "toporoom/domain/error.hpp"

namespace toporoom::domain {

class PointMm {
 public:
  static PointMm of(double x, double y) {
    if (!std::isfinite(x) || !std::isfinite(y)) {
      throw DomainError("PointMm coordinates must be finite millimetres",
                        "INVALID_POINT");
    }
    return PointMm(x, y);
  }

  double x() const noexcept { return x_; }
  double y() const noexcept { return y_; }

  double distance_to(const PointMm& other) const noexcept {
    const double dx = x_ - other.x_;
    const double dy = y_ - other.y_;
    return std::hypot(dx, dy);
  }

  bool equals(const PointMm& other, double epsilon = 1e-6) const noexcept {
    return std::abs(x_ - other.x_) <= epsilon &&
           std::abs(y_ - other.y_) <= epsilon;
  }

 private:
  PointMm(double x, double y) : x_(x), y_(y) {}
  double x_;
  double y_;
};

}  // namespace toporoom::domain
