import { describe, expect, it } from "vitest";
import { LengthMm, PointMm } from "@toporoom/domain-floorplan";
import { ParamGatheringFSM } from "./param-gathering-fsm.js";
import { WallDrawTool } from "./wall-draw-tool.js";

describe("ParamGatheringFSM / WallDrawTool", () => {
  it("collects start → end → thickness then yields an AddWall draft", () => {
    const fsm = ParamGatheringFSM.forTool(new WallDrawTool());
    expect(fsm.state).toBe("awaiting_start");

    fsm.provide("start", PointMm.of(0, 0));
    expect(fsm.state).toBe("awaiting_end");

    fsm.provide("end", PointMm.of(4000, 0));
    expect(fsm.state).toBe("awaiting_thickness");

    const draft = fsm.provide("thickness", LengthMm.of(200));
    expect(fsm.state).toBe("complete");
    expect(draft).toEqual({
      type: "AddWall",
      start: { x: 0, y: 0 },
      end: { x: 4000, y: 0 },
      thicknessMm: 200,
    });
  });

  it("rejects parameters that are out of order", () => {
    const fsm = ParamGatheringFSM.forTool(new WallDrawTool());
    expect(() => fsm.provide("end", PointMm.of(1, 0))).toThrow(/start/i);
  });
});
