import { readFileSync } from "node:fs";
import {
  MEASUREMENT_SOURCES,
  SCENE_IR_FORMAT,
  SCENE_IR_UNITS,
  SCENE_IR_VERSION,
  type SceneIR,
} from "@toporoom/domain-floorplan";

export function loadSceneIRFixture(path: string): SceneIR {
  const raw = JSON.parse(readFileSync(path, "utf8")) as unknown;
  const issues = validateSceneIR(raw);
  if (issues.length > 0) {
    throw new Error(`Invalid SceneIR fixture ${path}:\n${issues.join("\n")}`);
  }
  return raw as SceneIR;
}

export function validateSceneIR(raw: unknown): string[] {
  const issues: string[] = [];
  if (!raw || typeof raw !== "object") {
    return ["SceneIR must be an object"];
  }
  const scene = raw as Record<string, unknown>;
  if (scene.format !== SCENE_IR_FORMAT) {
    issues.push(`format must be ${SCENE_IR_FORMAT}`);
  }
  if (scene.version !== SCENE_IR_VERSION) {
    issues.push(`version must be ${SCENE_IR_VERSION}`);
  }
  if (scene.units !== SCENE_IR_UNITS) {
    issues.push("units must be mm");
  }
  if (typeof scene.id !== "string" || scene.id.length === 0) {
    issues.push("id is required");
  }
  if (!Array.isArray(scene.storeys) || scene.storeys.length === 0) {
    issues.push("at least one storey is required");
  }
  if (!Array.isArray(scene.measurements)) {
    issues.push("measurements must be an array");
  } else {
    for (const measurement of scene.measurements) {
      if (!measurement || typeof measurement !== "object") {
        issues.push("measurement must be an object");
        continue;
      }
      const source = (measurement as { source?: string }).source;
      if (!source || !(MEASUREMENT_SOURCES as readonly string[]).includes(source)) {
        issues.push(
          `measurement source must be one of ${MEASUREMENT_SOURCES.join("|")}`,
        );
      }
    }
  }
  return issues;
}
