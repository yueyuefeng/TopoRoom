#include "toporoom/app/editing_tools.hpp"

namespace toporoom::app {

void register_p0_editing_tools(ToolRegistry& registry) {
  registry.register_tool(WallDrawTool::kId);
  registry.register_tool(PlaceOpeningTool::kId);
  registry.register_tool(PlaceHostedComponentTool::kId);
  registry.register_tool(SetClearHeightTool::kId);
  registry.register_tool(SetStoreyHeightTool::kId);
}

}  // namespace toporoom::app
