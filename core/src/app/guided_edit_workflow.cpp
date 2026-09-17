#include "toporoom/app/guided_edit_workflow.hpp"

#include "toporoom/domain/floor_plan_document.hpp"

namespace toporoom::app {

GuidedEditWorkflow::GuidedEditWorkflow(ports::DocumentStorePort& store,
                                       ports::GeometryPort& geometry,
                                       SessionIsolate& isolate)
    : store_(store), rebuild_(geometry), edits_(store, rebuild_, isolate) {}

void GuidedEditWorkflow::begin(const std::string& document_id) {
  document_id_ = document_id;
  auto existing = store_.load(document_id);
  if (!existing) {
    auto created = domain::FloorPlanDocument::create(
        domain::CreateFloorPlanProps{document_id});
    store_.save(created.to_scene_ir());
    storey_id_ = created.storeys()[0].id();
  } else {
    storey_id_ = existing->storeys.empty() ? std::string() : existing->storeys[0].id;
    guide_.observe_scene(*existing, false);
  }
}

void GuidedEditWorkflow::mark_host_ok(bool ok) { guide_.mark_host_ok(ok); }

CommandResult GuidedEditWorkflow::observe(CommandResult result) {
  guide_.observe_scene(result.scene, result.rebuild.ok);
  return result;
}

CommandResult GuidedEditWorkflow::add_wall(AddWallCommand command) {
  command.document_id = document_id_;
  if (command.storey_id.empty()) command.storey_id = storey_id_;
  return observe(edits_.add_wall(command));
}

CommandResult GuidedEditWorkflow::add_opening(AddOpeningCommand command) {
  command.document_id = document_id_;
  if (command.storey_id.empty()) command.storey_id = storey_id_;
  return observe(edits_.add_opening(command));
}

CommandResult GuidedEditWorkflow::set_key_measurement(SetMeasurementCommand command,
                                                      bool typed_explicit) {
  command.document_id = document_id_;
  if (typed_explicit) {
    guide_.note_key_measurement(domain::MeasurementSource::Typed, true);
  }
  return observe(edits_.set_measurement(command));
}

CommandResult GuidedEditWorkflow::close_room(CloseRoomCommand command) {
  command.document_id = document_id_;
  if (command.storey_id.empty()) command.storey_id = storey_id_;
  return observe(edits_.close_room(command));
}

CommandResult GuidedEditWorkflow::set_room_attributes(SetRoomAttributesCommand command) {
  command.document_id = document_id_;
  if (command.storey_id.empty()) command.storey_id = storey_id_;
  return observe(edits_.set_room_attributes(command));
}

CommandResult GuidedEditWorkflow::set_storey_height(SetStoreyHeightCommand command) {
  command.document_id = document_id_;
  if (command.storey_id.empty()) command.storey_id = storey_id_;
  return observe(edits_.set_storey_height(command));
}

CommandResult GuidedEditWorkflow::place_hosted_component(
    PlaceHostedComponentCommand command) {
  command.document_id = document_id_;
  if (command.storey_id.empty()) command.storey_id = storey_id_;
  return observe(edits_.place_hosted_component(command));
}

}  // namespace toporoom::app
