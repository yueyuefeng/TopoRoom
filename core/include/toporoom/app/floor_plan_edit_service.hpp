#pragma once

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "toporoom/app/add_opening_handler.hpp"
#include "toporoom/app/add_wall_handler.hpp"
#include "toporoom/app/document_io.hpp"
#include "toporoom/app/session_isolate.hpp"
#include "toporoom/app/set_measurement_handler.hpp"
#include "toporoom/domain/kinds.hpp"

namespace toporoom::app {

struct MoveWallCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  double start_x = 0;
  double start_y = 0;
  double end_x = 0;
  double end_y = 0;
};

struct ResizeWallCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  double length_mm = 0;
};

struct DeleteWallCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
};

struct UpdateOpeningCommand {
  std::string document_id;
  std::string storey_id;
  std::string opening_id;
  domain::OpeningKind kind = domain::OpeningKind::Door;
  double width_mm = 0;
  double height_mm = 0;
  double offset_mm = 0;
  double sill_height_mm = 0;
};

struct DeleteOpeningCommand {
  std::string document_id;
  std::string storey_id;
  std::string opening_id;
};

struct CloseRoomCommand {
  std::string document_id;
  std::string storey_id;
  std::string room_id;
  std::vector<std::string> wall_ids;
  std::string name;
  domain::SpaceType space_type = domain::SpaceType::Interior;
  std::optional<double> clear_height_mm;
};

struct SetRoomAttributesCommand {
  std::string document_id;
  std::string storey_id;
  std::string room_id;
  std::string name;
  domain::SpaceType space_type = domain::SpaceType::Interior;
  std::optional<double> clear_height_mm;
};

struct SetStoreyHeightCommand {
  std::string document_id;
  std::string storey_id;
  double height_mm = 0;
  bool follow_matching_walls = true;
};

struct SetWallHeightCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  double height_mm = 0;
};

struct SetWallThicknessCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  double thickness_mm = 0;
};

struct SetWallKindCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  domain::WallKind kind = domain::WallKind::Masonry;
};

struct DemolishWallCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  bool force = false;
};

struct SplitWallCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  double offset_mm = 0;
};

struct PartialDemolishCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  double offset_mm = 0;
  double length_mm = 0;
  bool force = false;
};

struct PunchOpeningCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  std::optional<std::string> opening_id;
  domain::OpeningKind kind = domain::OpeningKind::Door;
  double width_mm = 900;
  double height_mm = 2100;
  double offset_mm = 800;
  double sill_height_mm = 0;
  bool force = false;
};

struct PlaceHostedComponentCommand {
  std::string document_id;
  std::string storey_id;
  std::optional<std::string> component_id;
  domain::HostedKind kind = domain::HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
  std::optional<std::string> host_wall_id;
};

struct UpdateHostedComponentCommand {
  std::string document_id;
  std::string storey_id;
  std::string component_id;
  domain::HostedKind kind = domain::HostedKind::Beam;
  double z_bottom_mm = 0;
  double depth_mm = 0;
  std::optional<std::string> host_wall_id;
};

struct DeleteHostedComponentCommand {
  std::string document_id;
  std::string storey_id;
  std::string component_id;
};

// Application command service for 户型建模 edits. Writes are serial per documentId (I9).
class FloorPlanEditService {
 public:
  FloorPlanEditService(ports::DocumentStorePort& store, GeometryRebuildPolicy& rebuild,
                       SessionIsolate& isolate)
      : store_(store), rebuild_(rebuild), isolate_(isolate) {}

  CommandResult add_wall(const AddWallCommand& command);
  CommandResult move_wall(const MoveWallCommand& command);
  CommandResult resize_wall(const ResizeWallCommand& command);
  CommandResult delete_wall(const DeleteWallCommand& command);
  CommandResult set_wall_height(const SetWallHeightCommand& command);
  CommandResult set_wall_thickness(const SetWallThicknessCommand& command);
  CommandResult set_wall_kind(const SetWallKindCommand& command);
  CommandResult demolish_wall(const DemolishWallCommand& command);
  CommandResult split_wall(const SplitWallCommand& command);
  CommandResult partial_demolish(const PartialDemolishCommand& command);
  CommandResult punch_opening(const PunchOpeningCommand& command);
  CommandResult add_opening(const AddOpeningCommand& command);
  CommandResult update_opening(const UpdateOpeningCommand& command);
  CommandResult delete_opening(const DeleteOpeningCommand& command);
  CommandResult close_room(const CloseRoomCommand& command);
  CommandResult set_room_attributes(const SetRoomAttributesCommand& command);
  CommandResult set_storey_height(const SetStoreyHeightCommand& command);
  CommandResult place_hosted_component(const PlaceHostedComponentCommand& command);
  CommandResult update_hosted_component(const UpdateHostedComponentCommand& command);
  CommandResult delete_hosted_component(const DeleteHostedComponentCommand& command);
  CommandResult set_measurement(const SetMeasurementCommand& command);

 private:
  CommandResult mutate(const std::string& document_id,
                       const std::function<void(domain::FloorPlanDocument&)>& fn);

  ports::DocumentStorePort& store_;
  GeometryRebuildPolicy& rebuild_;
  SessionIsolate& isolate_;
};

}  // namespace toporoom::app
