import { describe, expect, it } from "vitest";
import { FakeGeometryPort, semanticsFromSceneIR } from "./fakes/index.js";

describe("FakeGeometryPort", () => {
  const semantics = semanticsFromSceneIR({
    format: "toporoom.sceneir",
    version: "0.1",
    id: "doc_fake",
    units: "mm",
    revision: 1,
    storeys: [
      {
        id: "storey_1",
        elevationMm: 0,
        heightMm: 2800,
        walls: [
          {
            id: "wall_s",
            kind: "exterior",
            start: { x: 0, y: 0 },
            end: { x: 1000, y: 0 },
            thicknessMm: 200,
            heightMm: 2800,
            openings: [],
          },
        ],
        rooms: [],
      },
    ],
    measurements: [],
  });

  it("returns an ok MeshProjection with Wall_ node hints", async () => {
    const port = new FakeGeometryPort();
    const result = await port.rebuild({
      documentRev: 1,
      rebuildGeneration: 1,
      dirty: true,
      semantics,
    });
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.meshes.solids[0]?.nodeHint).toBe("Wall_wall_s");
    }
  });

  it("returns a Fault when instructed", async () => {
    const port = new FakeGeometryPort();
    port.failWith({
      code: "InvalidGeometry",
      message: "boom",
      entityIds: ["wall_s"],
    });
    const result = await port.rebuild({
      documentRev: 1,
      rebuildGeneration: 1,
      dirty: true,
      semantics,
    });
    expect(result).toEqual({
      ok: false,
      fault: {
        code: "InvalidGeometry",
        message: "boom",
        entityIds: ["wall_s"],
      },
    });
  });
});
