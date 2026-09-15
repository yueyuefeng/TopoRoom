#pragma once

#include <optional>
#include <string>

#include "toporoom/app/document_io.hpp"
#include "toporoom/domain/kinds.hpp"

namespace toporoom::app {

struct AddWallCommand {
  std::string document_id;
  std::string storey_id;
  std::optional<std::string> wall_id;
  double start_x = 0;
  double start_y = 0;
  double end_x = 0;
  double end_y = 0;
  double thickness_mm = 0;
  double height_mm = 0;
  domain::WallKind kind = domain::WallKind::Exterior;
};

class AddWallHandler {
 public:
  AddWallHandler(ports::DocumentStorePort& store, GeometryRebuildPolicy& rebuild)
      : store_(store), rebuild_(rebuild) {}

  CommandResult execute(const AddWallCommand& command);

 private:
  ports::DocumentStorePort& store_;
  GeometryRebuildPolicy& rebuild_;
};

}  // namespace toporoom::app
