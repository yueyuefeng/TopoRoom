import { LengthMm, PointMm } from "@toporoom/domain-floorplan";
import type { ToolDefinition, ToolStep } from "./param-gathering-fsm.js";

export interface AddWallDraft {
  type: "AddWall";
  start: { x: number; y: number };
  end: { x: number; y: number };
  thicknessMm: number;
}

const startStep: ToolStep<"start", PointMm> = {
  name: "start",
  parse: (value) => asPoint(value),
};

const endStep: ToolStep<"end", PointMm> = {
  name: "end",
  parse: (value) => asPoint(value),
};

const thicknessStep: ToolStep<"thickness", LengthMm> = {
  name: "thickness",
  parse: (value) => asLength(value),
};

export class WallDrawTool implements ToolDefinition<AddWallDraft> {
  readonly id = "WallDrawTool";
  readonly steps = [startStep, endStep, thicknessStep];

  complete(params: Record<string, unknown>): AddWallDraft {
    const start = asPoint(params.start);
    const end = asPoint(params.end);
    const thickness = asLength(params.thickness);
    return {
      type: "AddWall",
      start: { x: start.x, y: start.y },
      end: { x: end.x, y: end.y },
      thicknessMm: thickness.value,
    };
  }
}

function asPoint(value: unknown): PointMm {
  if (value instanceof PointMm) {
    return value;
  }
  if (
    value &&
    typeof value === "object" &&
    "x" in value &&
    "y" in value &&
    typeof value.x === "number" &&
    typeof value.y === "number"
  ) {
    return PointMm.of(value.x, value.y);
  }
  throw new Error("expected PointMm");
}

function asLength(value: unknown): LengthMm {
  if (value instanceof LengthMm) {
    return value;
  }
  if (typeof value === "number") {
    return LengthMm.of(value);
  }
  throw new Error("expected LengthMm");
}
