#include "toporoom/app/floor_plan_edit_service.hpp"

#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

namespace toporoom::app {

CommandResult FloorPlanEditService::mutate(
    const std::string& document_id,
    const std::function<void(domain::FloorPlanDocument&)>& fn) {
  return isolate_.enqueue(document_id, [&] {
    auto document = load_document(store_, document_id);
    fn(document);
    return commit(store_, rebuild_, document);
  });
}

CommandResult FloorPlanEditService::add_wall(const AddWallCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    domain::AddWallProps props;
    props.storey_id = command.storey_id;
    props.id = command.wall_id;
    props.start = domain::PointMm::of(command.start_x, command.start_y);
    props.end = domain::PointMm::of(command.end_x, command.end_y);
    props.thickness = domain::LengthMm::of(command.thickness_mm);
    props.height = domain::LengthMm::of(command.height_mm);
    props.kind = command.kind;
    document.add_wall(std::move(props));
  });
}

CommandResult FloorPlanEditService::move_wall(const MoveWallCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.move_wall(command.storey_id, command.wall_id,
                       domain::PointMm::of(command.start_x, command.start_y),
                       domain::PointMm::of(command.end_x, command.end_y));
  });
}

CommandResult FloorPlanEditService::resize_wall(const ResizeWallCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.resize_wall(command.storey_id, command.wall_id,
                         domain::LengthMm::of(command.length_mm));
  });
}

CommandResult FloorPlanEditService::delete_wall(const DeleteWallCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.delete_wall(command.storey_id, command.wall_id);
  });
}

CommandResult FloorPlanEditService::set_wall_height(const SetWallHeightCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.set_wall_height(command.storey_id, command.wall_id,
                             domain::LengthMm::of(command.height_mm));
  });
}

CommandResult FloorPlanEditService::add_opening(const AddOpeningCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    domain::AddOpeningProps props;
    props.storey_id = command.storey_id;
    props.wall_id = command.wall_id;
    props.id = command.opening_id;
    props.kind = command.kind;
    props.width = domain::LengthMm::of(command.width_mm);
    props.height = domain::LengthMm::of(command.height_mm);
    props.offset_along_wall = domain::LengthMm::of(command.offset_mm);
    props.sill_height = domain::LengthMm::of(command.sill_height_mm);
    document.add_opening(std::move(props));
  });
}

CommandResult FloorPlanEditService::update_opening(const UpdateOpeningCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.update_opening(command.storey_id, command.opening_id, command.kind,
                            domain::LengthMm::of(command.width_mm),
                            domain::LengthMm::of(command.height_mm),
                            domain::LengthMm::of(command.offset_mm),
                            domain::LengthMm::of(command.sill_height_mm));
  });
}

CommandResult FloorPlanEditService::delete_opening(const DeleteOpeningCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.delete_opening(command.storey_id, command.opening_id);
  });
}

CommandResult FloorPlanEditService::close_room(const CloseRoomCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    domain::CloseRoomProps props;
    props.storey_id = command.storey_id;
    props.id = command.room_id;
    props.wall_ids = command.wall_ids;
    props.name = command.name;
    props.space_type = command.space_type;
    if (command.clear_height_mm) {
      props.clear_height = domain::LengthMm::of(*command.clear_height_mm);
    }
    document.close_room(std::move(props));
  });
}

CommandResult FloorPlanEditService::set_room_attributes(
    const SetRoomAttributesCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    std::optional<domain::LengthMm> clear;
    if (command.clear_height_mm) {
      clear = domain::LengthMm::of(*command.clear_height_mm);
    }
    document.set_room_attributes(command.storey_id, command.room_id, command.name,
                                 command.space_type, clear);
  });
}

CommandResult FloorPlanEditService::set_storey_height(const SetStoreyHeightCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.set_storey_height(command.storey_id, domain::LengthMm::of(command.height_mm),
                               command.follow_matching_walls);
  });
}

CommandResult FloorPlanEditService::place_hosted_component(
    const PlaceHostedComponentCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    domain::PlaceHostedComponentProps props;
    props.storey_id = command.storey_id;
    props.id = command.component_id;
    props.kind = command.kind;
    props.z_bottom_mm = command.z_bottom_mm;
    props.depth_mm = command.depth_mm;
    props.host_wall_id = command.host_wall_id;
    document.place_hosted_component(std::move(props));
  });
}

CommandResult FloorPlanEditService::update_hosted_component(
    const UpdateHostedComponentCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.update_hosted_component(command.storey_id, command.component_id, command.kind,
                                     command.z_bottom_mm, command.depth_mm,
                                     command.host_wall_id);
  });
}

CommandResult FloorPlanEditService::delete_hosted_component(
    const DeleteHostedComponentCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    document.delete_hosted_component(command.storey_id, command.component_id);
  });
}

CommandResult FloorPlanEditService::set_measurement(const SetMeasurementCommand& command) {
  return mutate(command.document_id, [&](domain::FloorPlanDocument& document) {
    domain::SetMeasurementProps props;
    props.id = command.measurement_id;
    props.kind = command.kind;
    props.value = domain::LengthMm::of(command.value_mm);
    props.source = command.source;
    props.instrument_id = command.instrument_id;
    props.between = command.between;
    props.target = command.target;
    document.set_measurement(std::move(props));
  });
}

}  // namespace toporoom::app
