import { describe, expect, it } from "vitest";
import {
  FloorPlanDocument,
  LengthMm,
  PointMm,
} from "@toporoom/domain-floorplan";
import { FakeGeometryPort } from "@toporoom/ports/fakes";
import { ExportAppService } from "./export-app-service.js";
import { ExportRejectedError, StatusGate } from "./status-gate.js";

function rectangularScene() {
  const doc = FloorPlanDocument.create({ id: "doc_export" });
  const storeyId = doc.storeys[0]!.id;
  const walls = [
    {
      id: "wall_n",
      start: PointMm.of(0, 3000),
      end: PointMm.of(4000, 3000),
    },
    {
      id: "wall_e",
      start: PointMm.of(4000, 3000),
      end: PointMm.of(4000, 0),
    },
    {
      id: "wall_s",
      start: PointMm.of(4000, 0),
      end: PointMm.of(0, 0),
    },
    {
      id: "wall_w",
      start: PointMm.of(0, 0),
      end: PointMm.of(0, 3000),
    },
  ];
  for (const wall of walls) {
    doc.addWall({
      storeyId,
      id: wall.id,
      start: wall.start,
      end: wall.end,
      thickness: LengthMm.of(200),
      height: LengthMm.of(2800),
      kind: "exterior",
    });
  }
  doc.closeRoom({
    storeyId,
    id: "room_living",
    wallIds: ["wall_n", "wall_e", "wall_s", "wall_w"],
  });
  return doc.toSceneIR();
}

describe("StatusGate", () => {
  it("rejects a Fault rebuild and does not produce a structural solid", () => {
    const gate = new StatusGate();
    expect(() =>
      gate.assertExportable({
        ok: false,
        fault: {
          code: "NotManifold",
          message: "non-manifold solid",
          entityIds: ["wall_s"],
        },
      }),
    ).toThrow(ExportRejectedError);
  });

  it("allows export when rebuild status is OK", () => {
    const gate = new StatusGate();
    expect(() =>
      gate.assertExportable({
        ok: true,
        meshes: { solids: [] },
      }),
    ).not.toThrow();
  });
});

describe("ExportAppService + FakeGeometryPort", () => {
  it("refuses structural export when FakeGeometryPort returns Fault", async () => {
    const geometry = new FakeGeometryPort();
    geometry.failWith({
      code: "NotManifold",
      message: "broken boolean",
      entityIds: ["wall_s"],
    });
    const service = new ExportAppService(geometry);
    const scene = rectangularScene();
    const result = await service.exportSceneGraph(scene);
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.fault.code).toBe("NotManifold");
    }
  });

  it("exports a named scene graph when FakeGeometryPort returns MeshProjection", async () => {
    const geometry = new FakeGeometryPort();
    const service = new ExportAppService(geometry);
    const scene = rectangularScene();
    const result = await service.exportSceneGraph(scene);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.graph.nodes.some((n) => n.name.startsWith("Storey_"))).toBe(
        true,
      );
      expect(result.graph.nodes.some((n) => n.name.startsWith("Wall_"))).toBe(
        true,
      );
      expect(result.graph.nodes.some((n) => n.name.startsWith("Room_"))).toBe(
        true,
      );
    }
  });
});
