import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { exportSceneGraph } from "@toporoom/adapter-export-gltf";
import {
  FloorPlanDocument,
  MEASUREMENT_SOURCES,
  SCENE_IR_FORMAT,
  SCENE_IR_UNITS,
  SCENE_IR_VERSION,
  type SceneIR,
} from "@toporoom/domain-floorplan";
import { FakeGeometryPort, semanticsFromSceneIR } from "@toporoom/ports/fakes";
import { loadSceneIRFixture, validateSceneIR } from "./load-sceneir.js";

const FIXTURE_PATH = join(
  dirname(fileURLToPath(import.meta.url)),
  "../fixtures/rect-room-door-laser.sceneir.json",
);

describe("SceneIR 0.1 fixture: rectangular room + door + laser", () => {
  it("loads and validates the published-language snapshot", () => {
    const scene = loadSceneIRFixture(FIXTURE_PATH);
    const issues = validateSceneIR(scene);
    expect(issues).toEqual([]);
    expect(scene.format).toBe(SCENE_IR_FORMAT);
    expect(scene.version).toBe(SCENE_IR_VERSION);
    expect(scene.units).toBe(SCENE_IR_UNITS);
    expect(scene.storeys[0]?.rooms[0]?.id).toBe("room_living");
    expect(scene.storeys[0]?.walls.some((w) => w.openings.length > 0)).toBe(
      true,
    );
    expect(scene.measurements[0]?.source).toBe("laser");
    expect(MEASUREMENT_SOURCES).toContain(scene.measurements[0]?.source);
  });

  it("reconstitutes a FloorPlanDocument without domain errors", () => {
    const scene = loadSceneIRFixture(FIXTURE_PATH);
    const document = FloorPlanDocument.fromSceneIR(scene);
    expect(document.storeys[0]?.rooms[0]?.id).toBe("room_living");
    expect(document.measurements[0]?.source).toBe("laser");
    expect(document.toSceneIR().storeys[0]?.walls).toHaveLength(4);
  });

  it("exports Storey_/Wall_/Room_ node names from the fixture", async () => {
    const scene = loadSceneIRFixture(FIXTURE_PATH);
    const geometry = new FakeGeometryPort();
    const rebuilt = await geometry.rebuild({
      documentRev: scene.revision,
      rebuildGeneration: 1,
      dirty: true,
      semantics: semanticsFromSceneIR(scene),
    });
    expect(rebuilt.ok).toBe(true);
    if (!rebuilt.ok) {
      return;
    }
    const graph = exportSceneGraph(scene, rebuilt.meshes);
    const names = graph.nodes.map((node) => node.name);
    expect(names).toContain("Storey_storey_1");
    expect(names).toContain("Wall_wall_s");
    expect(names).toContain("Room_room_living");
    expect(names).toContain("Opening_op_door");
  });

  it("rejects a fixture that claims a forbidden measurement source", () => {
    const raw = JSON.parse(readFileSync(FIXTURE_PATH, "utf8")) as SceneIR;
    const broken = {
      ...raw,
      measurements: [
        { ...raw.measurements[0]!, source: "rf_ble" as "laser" },
      ],
    };
    expect(validateSceneIR(broken).join(" ")).toMatch(/source/i);
  });
});
