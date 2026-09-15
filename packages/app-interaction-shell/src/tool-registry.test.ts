import { describe, expect, it } from "vitest";
import { ToolRegistry } from "./tool-registry.js";
import { WallDrawTool } from "./wall-draw-tool.js";

describe("ToolRegistry", () => {
  it("registers and retrieves tools by id", () => {
    const registry = new ToolRegistry();
    const tool = new WallDrawTool();
    registry.register(tool);
    expect(registry.get("WallDrawTool")).toBe(tool);
    expect(registry.list().map((item) => item.id)).toEqual(["WallDrawTool"]);
  });

  it("rejects duplicate tool ids", () => {
    const registry = new ToolRegistry();
    registry.register(new WallDrawTool());
    expect(() => registry.register(new WallDrawTool())).toThrow(/already registered/i);
  });
});
