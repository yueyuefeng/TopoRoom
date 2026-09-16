#pragma once

#include <optional>
#include <string>

#include "toporoom/app/document_io.hpp"
#include "toporoom/domain/kinds.hpp"

namespace toporoom::app {

struct AddOpeningCommand {
  std::string document_id;
  std::string storey_id;
  std::string wall_id;
  std::optional<std::string> opening_id;
  domain::OpeningKind kind = domain::OpeningKind::Door;
  double width_mm = 0;
  double height_mm = 0;
  double offset_mm = 0;
  double sill_height_mm = 0;
};

class AddOpeningHandler {
 public:
  AddOpeningHandler(ports::DocumentStorePort& store, GeometryRebuildPolicy& rebuild)
      : store_(store), rebuild_(rebuild) {}

  CommandResult execute(const AddOpeningCommand& command);

 private:
  ports::DocumentStorePort& store_;
  GeometryRebuildPolicy& rebuild_;
};

}  // namespace toporoom::app
