#include <stdexcept>
#include <string>

#include <gtest/gtest.h>

#include "toporoom/app/tool_registry.hpp"
#include "toporoom/app/wall_draw_tool.hpp"

using toporoom::app::ToolRegistry;
using toporoom::app::WallDrawTool;

TEST(ToolRegistry, RegistersAndLists) {
  ToolRegistry registry;
  registry.register_tool(WallDrawTool::kId);
  EXPECT_TRUE(registry.has("WallDrawTool"));
  ASSERT_EQ(registry.list().size(), 1u);
  EXPECT_EQ(registry.list()[0], "WallDrawTool");
}

TEST(ToolRegistry, RejectsDuplicates) {
  ToolRegistry registry;
  registry.register_tool(WallDrawTool::kId);
  EXPECT_THROW(registry.register_tool(WallDrawTool::kId), std::runtime_error);
}
