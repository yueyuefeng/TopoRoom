#pragma once

#include <string>
#include <variant>
#include <vector>

#include "toporoom/domain/kinds.hpp"

namespace toporoom::domain {

struct WallAdded {
  static constexpr const char* kType = "WallAdded";
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
};

struct OpeningAdded {
  static constexpr const char* kType = "OpeningAdded";
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  std::string opening_id;
  OpeningKind kind = OpeningKind::Door;
};

struct RoomClosed {
  static constexpr const char* kType = "RoomClosed";
  std::string document_id;
  std::string storey_id;
  std::string room_id;
  std::vector<std::string> wall_ids;
};

struct RoomAttributesChanged {
  static constexpr const char* kType = "RoomAttributesChanged";
  std::string document_id;
  std::string storey_id;
  std::string room_id;
};

struct StoreyHeightChanged {
  static constexpr const char* kType = "StoreyHeightChanged";
  std::string document_id;
  std::string storey_id;
  double height_mm = 0;
};

struct HostedComponentPlaced {
  static constexpr const char* kType = "HostedComponentPlaced";
  std::string document_id;
  std::string storey_id;
  std::string component_id;
  HostedKind kind = HostedKind::Beam;
};

struct FloorPlanSemanticsChanged {
  static constexpr const char* kType = "FloorPlanSemanticsChanged";
  std::string document_id;
  int revision = 0;
};

using DomainEvent =
    std::variant<WallAdded, OpeningAdded, RoomClosed, RoomAttributesChanged,
                 StoreyHeightChanged, HostedComponentPlaced, FloorPlanSemanticsChanged>;

inline const char* event_type(const DomainEvent& event) {
  return std::visit([](const auto& e) { return e.kType; }, event);
}

}  // namespace toporoom::domain
