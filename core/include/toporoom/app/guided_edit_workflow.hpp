#pragma once

#include <string>

#include "toporoom/app/floor_plan_edit_service.hpp"
#include "toporoom/app/guided_room_session.hpp"
#include "toporoom/ports/document_store_port.hpp"
#include "toporoom/ports/geometry_port.hpp"

namespace toporoom::app {

// Real multi-step 量房编辑 path: each step writes FloorPlanDocument through
// FloorPlanEditService + SessionIsolate, then the guide observes SceneIR.
class GuidedEditWorkflow {
 public:
  GuidedEditWorkflow(ports::DocumentStorePort& store, ports::GeometryPort& geometry,
                     SessionIsolate& isolate);

  void begin(const std::string& document_id);
  void mark_host_ok(bool ok);

  CommandResult add_wall(AddWallCommand command);
  CommandResult add_opening(AddOpeningCommand command);
  CommandResult set_key_measurement(SetMeasurementCommand command, bool typed_explicit);
  CommandResult close_room(CloseRoomCommand command);
  CommandResult set_room_attributes(SetRoomAttributesCommand command);
  CommandResult set_storey_height(SetStoreyHeightCommand command);
  CommandResult place_hosted_component(PlaceHostedComponentCommand command);

  const GuidedRoomSession& guide() const noexcept { return guide_; }
  GuidedRoomSession& guide() noexcept { return guide_; }
  bool can_export() const { return guide_.can_export(); }
  GuidePhase phase() const { return guide_.phase(); }
  const std::string& document_id() const noexcept { return document_id_; }
  const std::string& storey_id() const noexcept { return storey_id_; }

 private:
  CommandResult observe(CommandResult result);

  ports::DocumentStorePort& store_;
  GeometryRebuildPolicy rebuild_;
  FloorPlanEditService edits_;
  GuidedRoomSession guide_;
  std::string document_id_;
  std::string storey_id_;
};

}  // namespace toporoom::app
