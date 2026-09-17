#pragma once

#include <string>
#include <vector>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"

namespace toporoom::domain {

// Opening = 洞口. kind is required: door=门洞, window=窗洞, archway=垭口 (I3 / I12).
// width is 净宽意图 (D5). sill is 窗台高.
struct OpeningProps {
  std::string id;
  OpeningKind kind = OpeningKind::Door;
  LengthMm width = LengthMm::zero();
  LengthMm height = LengthMm::zero();
  LengthMm offset_along_wall = LengthMm::zero();
  LengthMm sill_height = LengthMm::zero();
};

class Opening {
 public:
  static Opening create(OpeningProps props);

  const std::string& id() const noexcept { return id_; }
  OpeningKind kind() const noexcept { return kind_; }
  LengthMm width() const noexcept { return width_; }
  LengthMm height() const noexcept { return height_; }
  LengthMm offset_along_wall() const noexcept { return offset_along_wall_; }
  LengthMm sill_height() const noexcept { return sill_height_; }

  Opening with_width(LengthMm width) const;
  Opening with_kind(OpeningKind kind) const;
  Opening with_placement(LengthMm width, LengthMm height, LengthMm offset_along_wall,
                         LengthMm sill_height) const;
  double occupies_until_mm() const noexcept {
    return offset_along_wall_.value() + width_.value();
  }

 private:
  explicit Opening(OpeningProps props);
  std::string id_;
  OpeningKind kind_;
  LengthMm width_;
  LengthMm height_;
  LengthMm offset_along_wall_;
  LengthMm sill_height_;
};

}  // namespace toporoom::domain
