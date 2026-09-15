#include "toporoom/app/add_wall_handler.hpp"

#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"

namespace toporoom::app {

CommandResult AddWallHandler::execute(const AddWallCommand& command) {
  auto document = load_document(store_, command.document_id);
  domain::AddWallProps props;
  props.storey_id = command.storey_id;
  props.id = command.wall_id;
  props.start = domain::PointMm::of(command.start_x, command.start_y);
  props.end = domain::PointMm::of(command.end_x, command.end_y);
  props.thickness = domain::LengthMm::of(command.thickness_mm);
  props.height = domain::LengthMm::of(command.height_mm);
  props.kind = command.kind;
  document.add_wall(std::move(props));
  return commit(store_, rebuild_, document);
}

}  // namespace toporoom::app
