#pragma once

#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include "toporoom/app/param_gathering_fsm.hpp"
#include "toporoom/app/tool_registry.hpp"
#include "toporoom/app/wall_draw_tool.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/length_mm.hpp"

namespace toporoom::app {

inline std::string require_param(const std::unordered_map<std::string, std::string>& params,
                                 const char* key) {
  auto it = params.find(key);
  if (it == params.end()) {
    throw std::runtime_error(std::string("missing ") + key);
  }
  return it->second;
}

struct PlaceOpeningDraft {
  std::string type = "PlaceOpening";
  std::string wall_id;
  domain::OpeningKind kind = domain::OpeningKind::Door;
  double offset_mm = 0;
  double width_mm = 0;
  double height_mm = 0;
  double sill_height_mm = 0;
};

class PlaceOpeningTool {
 public:
  static constexpr const char* kId = "PlaceOpening";

  ParamGatheringFSM create_fsm() const {
    std::vector<ToolStep> steps;
    steps.push_back(ToolStep{"wall_id", [](const std::string& raw, auto& out) {
                               out["wall_id"] = raw;
                             }});
    steps.push_back(ToolStep{"kind", [](const std::string& raw, auto& out) {
                               const auto parsed = domain::opening_kind_from_string(raw);
                               if (!parsed) {
                                 throw std::runtime_error(
                                     "OpeningKind required: door|window|archway (门洞/窗洞/垭口)");
                               }
                               out["kind"] = raw;
                             }});
    steps.push_back(ToolStep{
        "offset", [](const std::string& raw, auto& out) { out["offset"] = raw; }});
    steps.push_back(ToolStep{
        "width", [](const std::string& raw, auto& out) { out["width"] = raw; }});
    steps.push_back(ToolStep{
        "height", [](const std::string& raw, auto& out) { out["height"] = raw; }});
    steps.push_back(
        ToolStep{"sill", [](const std::string& raw, auto& out) { out["sill"] = raw; }});
    return ParamGatheringFSM(kId, std::move(steps));
  }

  static PlaceOpeningDraft complete(const std::unordered_map<std::string, std::string>& params) {
    PlaceOpeningDraft draft;
    draft.wall_id = require_param(params, "wall_id");
    draft.kind = *domain::opening_kind_from_string(require_param(params, "kind"));
    draft.offset_mm = std::stod(require_param(params, "offset"));
    draft.width_mm = std::stod(require_param(params, "width"));
    draft.height_mm = std::stod(require_param(params, "height"));
    draft.sill_height_mm = std::stod(require_param(params, "sill"));
    domain::LengthMm::of(draft.width_mm);
    domain::LengthMm::of(draft.height_mm);
    return draft;
  }
};

struct PlaceHostedComponentDraft {
  std::string type = "PlaceHostedComponent";
  domain::HostedKind kind = domain::HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
  std::string host_wall_id;
};

class PlaceHostedComponentTool {
 public:
  static constexpr const char* kId = "PlaceHostedComponent";

  ParamGatheringFSM create_fsm() const {
    std::vector<ToolStep> steps;
    steps.push_back(ToolStep{"kind", [](const std::string& raw, auto& out) {
                               const auto parsed = domain::hosted_kind_from_string(raw);
                               if (!parsed) {
                                 throw std::runtime_error(
                                     "HostedKind required: beam|column|flue (梁/柱/烟道)");
                               }
                               out["kind"] = raw;
                             }});
    steps.push_back(ToolStep{"z_bottom", [](const std::string& raw, auto& out) {
                               out["z_bottom"] = raw;
                             }});
    steps.push_back(ToolStep{
        "depth", [](const std::string& raw, auto& out) { out["depth"] = raw; }});
    steps.push_back(ToolStep{"host_wall", [](const std::string& raw, auto& out) {
                               out["host_wall"] = raw;
                             }});
    return ParamGatheringFSM(kId, std::move(steps));
  }

  static PlaceHostedComponentDraft complete(
      const std::unordered_map<std::string, std::string>& params) {
    PlaceHostedComponentDraft draft;
    draft.kind = *domain::hosted_kind_from_string(require_param(params, "kind"));
    draft.z_bottom_mm = std::stod(require_param(params, "z_bottom"));
    draft.depth_mm = std::stod(require_param(params, "depth"));
    draft.host_wall_id = require_param(params, "host_wall");
    return draft;
  }
};

struct SetClearHeightDraft {
  std::string type = "SetClearHeight";
  std::string room_id;
  double clear_height_mm = 0;
};

class SetClearHeightTool {
 public:
  static constexpr const char* kId = "SetClearHeight";

  ParamGatheringFSM create_fsm() const {
    std::vector<ToolStep> steps;
    steps.push_back(ToolStep{
        "room_id", [](const std::string& raw, auto& out) { out["room_id"] = raw; }});
    steps.push_back(ToolStep{"clear_height", [](const std::string& raw, auto& out) {
                               out["clear_height"] = raw;
                             }});
    return ParamGatheringFSM(kId, std::move(steps));
  }

  static SetClearHeightDraft complete(
      const std::unordered_map<std::string, std::string>& params) {
    SetClearHeightDraft draft;
    draft.room_id = require_param(params, "room_id");
    draft.clear_height_mm = std::stod(require_param(params, "clear_height"));
    domain::LengthMm::of(draft.clear_height_mm);
    return draft;
  }
};

struct SetStoreyHeightDraft {
  std::string type = "SetStoreyHeight";
  double height_mm = 0;
  bool follow_matching_walls = true;
};

class SetStoreyHeightTool {
 public:
  static constexpr const char* kId = "SetStoreyHeight";

  ParamGatheringFSM create_fsm() const {
    std::vector<ToolStep> steps;
    steps.push_back(ToolStep{
        "height", [](const std::string& raw, auto& out) { out["height"] = raw; }});
    steps.push_back(ToolStep{"follow", [](const std::string& raw, auto& out) {
                               out["follow"] = raw;
                             }});
    return ParamGatheringFSM(kId, std::move(steps));
  }

  static SetStoreyHeightDraft complete(
      const std::unordered_map<std::string, std::string>& params) {
    SetStoreyHeightDraft draft;
    draft.height_mm = std::stod(require_param(params, "height"));
    const auto follow = require_param(params, "follow");
    draft.follow_matching_walls = follow != "0" && follow != "false";
    domain::LengthMm::of(draft.height_mm);
    return draft;
  }
};

void register_p0_editing_tools(ToolRegistry& registry);

}  // namespace toporoom::app
