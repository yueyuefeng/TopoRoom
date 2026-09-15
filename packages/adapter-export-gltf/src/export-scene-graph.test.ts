import { describe, expect, it } from "vitest";
import {
  FloorPlanDocument,
  LengthMm,
  PointMm,
} from "@toporoom/domain-floorplan";
import { FakeGeometryPort, semanticsFromSceneIR } from "@toporoom/ports/fakes";
import { exportGltfJson, exportSceneGraph } from "./export-scene-graph.js";

function sampleScene() {
  const doc = FloorPlanDocument.create({ id: "doc_gltf" });
  const storeyId = doc.storeys[0]!.id;
  doc.addWall({
    storeyId,
    id: "wall_s",
    start: PointMm.of(0, 0),
    end: PointMm.of(4000, 0),
    thickness: LengthMm.of(200),
    height: LengthMm.of(2800),
    kind: "exterior",
  });
  doc.addOpening({
    storeyId,
    wallId: "wall_s",
    id: "op_door",
    kind: "door",
    width: LengthMm.of(900),
    height: LengthMm.of(2100),
    offsetAlongWall: LengthMm.of(800),
    sillHeight: LengthMm.of(0),
  });
  doc.addWall({
    storeyId,
    id: "wall_e",
    start: PointMm.of(4000, 0),
    end: PointMm.of(4000, 3000),
    thickness: LengthMm.of(200),
    height: LengthMm.of(2800),
    kind: "exterior",
  });
  doc.addWall({
    storeyId,
    id: "wall_n",
    start: PointMm.of(4000, 3000),
    end: PointMm.of(0, 3000),
    thickness: LengthMm.of(200),
    height: LengthMm.of(2800),
    kind: "exterior",
  });
  doc.addWall({
    storeyId,
    id: "wall_w",
    start: PointMm.of(0, 3000),
    end: PointMm.of(0, 0),
    thickness: LengthMm.of(200),
    height: LengthMm.of(2800),
    kind: "exterior",
  });
  doc.closeRoom({
    storeyId,
    id: "room_living",
    wallIds: ["wall_s", "wall_e", "wall_n", "wall_w"],
  });
  return doc.toSceneIR();
}

describe("exportSceneGraph", () => {
  it("names nodes Storey_ / Wall_ / Room_ / Opening_ with extras.toporoomId", async () => {
    const scene = sampleScene();
    const geometry = new FakeGeometryPort();
    const rebuilt = await geometry.rebuild({
      documentRev: scene.revision,
      rebuildGeneration: 1,
      dirty: true,
      semantics: semanticsFromSceneIR(scene),
    });
    if (!rebuilt.ok) {
      throw new Error("expected ok mesh");
    }
    const graph = exportSceneGraph(scene, rebuilt.meshes);
    const names = graph.nodes.map((node) => node.name);
    expect(names).toContain(`Storey_${scene.storeys[0]!.id}`);
    expect(names).toContain("Wall_wall_s");
    expect(names).toContain("Room_room_living");
    expect(names).toContain("Opening_op_door");
    expect(graph.nodes.every((node) => node.extras.toporoomId)).toBe(true);
    expect(graph.sourceUnits).toBe("mm");
    expect(graph.units).toBe("m");
  });
});

describe("exportGltfJson", () => {
  it("emits a minimal glTF 2.0 document with compiler generator and metre conversion", async () => {
    const scene = sampleScene();
    const geometry = new FakeGeometryPort();
    const rebuilt = await geometry.rebuild({
      documentRev: scene.revision,
      rebuildGeneration: 1,
      dirty: true,
      semantics: semanticsFromSceneIR(scene),
    });
    if (!rebuilt.ok) {
      throw new Error("expected ok mesh");
    }
    const gltf = exportGltfJson(scene, rebuilt.meshes);
    expect(gltf.asset.version).toBe("2.0");
    expect(gltf.asset.generator).toMatch(/^toporoom-compiler\//);
    expect(gltf.nodes?.some((n) => n.name === "Wall_wall_s")).toBe(true);
    const storey = gltf.nodes?.find((n) => n.name?.startsWith("Storey_"));
    expect(storey?.extras).toMatchObject({
      toporoomId: scene.storeys[0]!.id,
      kind: "storey",
    });
    const wallSolid = rebuilt.meshes.solids.find((s) => s.entityId === "wall_s");
    const firstVertexM = (wallSolid?.verticesMm[0] ?? 0) / 1000;
    expect(gltf.meshes?.[0]?.primitives[0]?.attributes.POSITION).toBe(0);
    expect(gltf.accessors?.[0]?.max?.[0]).toBeGreaterThanOrEqual(firstVertexM);
  });
});
