#include <gtest/gtest.h>

#include "toporoom/app/param_gathering_fsm.hpp"
#include "toporoom/app/wall_draw_tool.hpp"

using toporoom::app::WallDrawTool;

TEST(ParamGatheringFSM, CollectsStartEndThickness) {
  WallDrawTool tool;
  auto fsm = tool.create_fsm();
  EXPECT_EQ(fsm.state(), "awaiting_start");
  fsm.provide("start", "0,0");
  EXPECT_EQ(fsm.state(), "awaiting_end");
  fsm.provide("end", "4000,0");
  EXPECT_EQ(fsm.state(), "awaiting_thickness");
  fsm.provide("thickness", "200");
  EXPECT_EQ(fsm.state(), "complete");
  const auto draft = WallDrawTool::complete(fsm.params());
  EXPECT_EQ(draft.type, "AddWall");
  EXPECT_EQ(draft.start_x, 0);
  EXPECT_EQ(draft.end_x, 4000);
  EXPECT_EQ(draft.thickness_mm, 200);
}

TEST(ParamGatheringFSM, RejectsOutOfOrder) {
  auto fsm = WallDrawTool().create_fsm();
  EXPECT_THROW(fsm.provide("end", "1,0"), std::runtime_error);
}
