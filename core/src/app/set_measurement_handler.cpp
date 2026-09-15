#include "toporoom/app/set_measurement_handler.hpp"

#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"

namespace toporoom::app {

CommandResult SetMeasurementHandler::execute(const SetMeasurementCommand& command) {
  auto document = load_document(store_, command.document_id);
  domain::SetMeasurementProps props;
  props.id = command.measurement_id;
  props.kind = command.kind;
  props.value = domain::LengthMm::of(command.value_mm);
  props.source = command.source;
  props.instrument_id = command.instrument_id;
  props.between = command.between;
  props.target = command.target;
  document.set_measurement(std::move(props));
  return commit(store_, rebuild_, document);
}

}  // namespace toporoom::app
