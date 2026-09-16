#include <cmath>
#include <limits>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/length_mm.hpp"

using toporoom::domain::DomainError;
using toporoom::domain::LengthMm;

TEST(LengthMm, AcceptsZeroAndPositive) {
  EXPECT_EQ(LengthMm::of(0).value(), 0);
  EXPECT_EQ(LengthMm::of(900).value(), 900);
}

TEST(LengthMm, RejectsNegative) {
  EXPECT_THROW(LengthMm::of(-1), DomainError);
  try {
    LengthMm::of(-1);
    FAIL();
  } catch (const DomainError& error) {
    EXPECT_NE(std::string(error.what()).find("negative"), std::string::npos);
  }
}

TEST(LengthMm, RejectsNonFinite) {
  EXPECT_THROW(LengthMm::of(std::numeric_limits<double>::quiet_NaN()), DomainError);
  EXPECT_THROW(LengthMm::of(std::numeric_limits<double>::infinity()), DomainError);
}

TEST(LengthMm, EqualsByValue) {
  EXPECT_TRUE(LengthMm::of(120).equals(LengthMm::of(120)));
  EXPECT_FALSE(LengthMm::of(120).equals(LengthMm::of(121)));
}
