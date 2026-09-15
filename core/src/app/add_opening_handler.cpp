#include "toporoom/app/add_opening_handler.hpp"

#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"

namespace toporoom::app {

CommandResult AddOpeningHandler::execute(const AddOpeningCommand& command) {
  auto document = load_document(store_, command.document_id);
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
  return commit(store_, rebuild_, document);
}

}  // namespace toporoom::app
