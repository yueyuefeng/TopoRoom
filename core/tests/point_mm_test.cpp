#include <cmath>
#include <limits>

#include <gtest/gtest.h>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/point_mm.hpp"

using toporoom::domain::DomainError;
using toporoom::domain::PointMm;

TEST(PointMm, DistanceAndEquality) {
  const auto a = PointMm::of(0, 0);
  const auto b = PointMm::of(4000, 0);
  EXPECT_EQ(a.distance_to(b), 4000);
  EXPECT_TRUE(a.equals(PointMm::of(0, 0)));
  EXPECT_FALSE(a.equals(b));
}

TEST(PointMm, RejectsNonFinite) {
  EXPECT_THROW(PointMm::of(std::numeric_limits<double>::quiet_NaN(), 0), DomainError);
  EXPECT_THROW(PointMm::of(0, std::numeric_limits<double>::infinity()), DomainError);
}
