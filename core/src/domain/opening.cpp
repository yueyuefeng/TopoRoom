#include "toporoom/domain/opening.hpp"

#include "toporoom/domain/error.hpp"

namespace toporoom::domain {

Opening::Opening(OpeningProps props)
    : id_(std::move(props.id)),
      kind_(props.kind),
      width_(props.width),
      height_(props.height),
      offset_along_wall_(props.offset_along_wall),
      sill_height_(props.sill_height) {}

Opening Opening::create(OpeningProps props) {
  if (props.width.value() <= 0) {
    throw DomainError("Opening width must be positive", "INVALID_OPENING");
  }
  if (props.height.value() <= 0) {
    throw DomainError("Opening height must be positive", "INVALID_OPENING");
  }
  return Opening(std::move(props));
}

Opening Opening::with_width(LengthMm width) const {
  return with_placement(width, height_, offset_along_wall_, sill_height_);
}

Opening Opening::with_kind(OpeningKind kind) const {
  OpeningProps props;
  props.id = id_;
  props.kind = kind;
  props.width = width_;
  props.height = height_;
  props.offset_along_wall = offset_along_wall_;
  props.sill_height = sill_height_;
  return Opening::create(std::move(props));
}

Opening Opening::with_placement(LengthMm width, LengthMm height, LengthMm offset_along_wall,
                                LengthMm sill_height) const {
  OpeningProps props;
  props.id = id_;
  props.kind = kind_;
  props.width = width;
  props.height = height;
  props.offset_along_wall = offset_along_wall;
  props.sill_height = sill_height;
  return Opening::create(std::move(props));
}

}  // namespace toporoom::domain
