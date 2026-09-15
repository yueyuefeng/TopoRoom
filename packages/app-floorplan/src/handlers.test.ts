import { describe, expect, it } from "vitest";
import {
  FloorPlanDocument,
  LengthMm,
  PointMm,
} from "@toporoom/domain-floorplan";
import { FakeGeometryPort, InMemoryDocumentStore } from "@toporoom/ports/fakes";
import { AddOpeningHandler } from "./add-opening-handler.js";
import { AddWallHandler } from "./add-wall-handler.js";
import { GeometryRebuildPolicy } from "./rebuild-policy.js";
import { SetMeasurementHandler } from "./set-measurement-handler.js";

async function setup() {
  const store = new InMemoryDocumentStore();
  const geometry = new FakeGeometryPort();
  const rebuild = new GeometryRebuildPolicy(geometry);
  const doc = FloorPlanDocument.create({ id: "doc_1" });
  await store.save(doc.toSceneIR());
  return {
    store,
    geometry,
    addWall: new AddWallHandler(store, rebuild),
    addOpening: new AddOpeningHandler(store, rebuild),
    setMeasurement: new SetMeasurementHandler(store, rebuild),
    storeyId: doc.storeys[0]!.id,
  };
}

describe("floorplan command handlers", () => {
  it("AddWall mutates the document, emits WallAdded, and rebuilds", async () => {
    const ctx = await setup();
    const result = await ctx.addWall.execute({
      documentId: "doc_1",
      storeyId: ctx.storeyId,
      wallId: "wall_s",
      start: { x: 0, y: 0 },
      end: { x: 4000, y: 0 },
      thicknessMm: 200,
      heightMm: 2800,
      kind: "exterior",
    });
    expect(result.events.map((e) => e.type)).toContain("WallAdded");
    expect(result.rebuild.ok).toBe(true);
    expect(ctx.geometry.lastBuildRequest?.semantics.documentId).toBe("doc_1");
    const saved = await ctx.store.load("doc_1");
    expect(saved?.storeys[0]?.walls).toHaveLength(1);
  });

  it("AddOpening mutates the host wall and emits OpeningAdded", async () => {
    const ctx = await setup();
    await ctx.addWall.execute({
      documentId: "doc_1",
      storeyId: ctx.storeyId,
      wallId: "wall_s",
      start: { x: 0, y: 0 },
      end: { x: 4000, y: 0 },
      thicknessMm: 200,
      heightMm: 2800,
      kind: "exterior",
    });
    const result = await ctx.addOpening.execute({
      documentId: "doc_1",
      storeyId: ctx.storeyId,
      wallId: "wall_s",
      openingId: "op_door",
      kind: "door",
      widthMm: 900,
      heightMm: 2100,
      offsetMm: 800,
      sillHeightMm: 0,
    });
    expect(result.events.map((e) => e.type)).toContain("OpeningAdded");
    const saved = await ctx.store.load("doc_1");
    expect(saved?.storeys[0]?.walls[0]?.openings[0]?.id).toBe("op_door");
  });

  it("SetMeasurement writes laser source onto SceneIR and resizes the opening", async () => {
    const ctx = await setup();
    await ctx.addWall.execute({
      documentId: "doc_1",
      storeyId: ctx.storeyId,
      wallId: "wall_s",
      start: { x: 0, y: 0 },
      end: { x: 4000, y: 0 },
      thicknessMm: 200,
      heightMm: 2800,
      kind: "exterior",
    });
    await ctx.addOpening.execute({
      documentId: "doc_1",
      storeyId: ctx.storeyId,
      wallId: "wall_s",
      openingId: "op_door",
      kind: "door",
      widthMm: 800,
      heightMm: 2100,
      offsetMm: 800,
      sillHeightMm: 0,
    });
    const result = await ctx.setMeasurement.execute({
      documentId: "doc_1",
      measurementId: "m_door",
      kind: "length",
      valueMm: 900,
      source: "laser",
      instrumentId: "laser_sku_x",
      target: { entityType: "opening", entityId: "op_door", field: "width" },
    });
    expect(result.events.map((e) => e.type)).toContain(
      "FloorPlanSemanticsChanged",
    );
    const saved = await ctx.store.load("doc_1");
    expect(saved?.measurements[0]).toMatchObject({
      source: "laser",
      valueMm: 900,
    });
    expect(saved?.storeys[0]?.walls[0]?.openings[0]?.widthMm).toBe(900);
  });

  it("RebuildPolicy calls GeometryPort when semantics change", async () => {
    const ctx = await setup();
    ctx.geometry.failWith({
      code: "NotClosed",
      message: "room not closed",
      entityIds: [ctx.storeyId],
    });
    const result = await ctx.addWall.execute({
      documentId: "doc_1",
      storeyId: ctx.storeyId,
      wallId: "wall_s",
      start: { x: 0, y: 0 },
      end: { x: 4000, y: 0 },
      thicknessMm: 200,
      heightMm: 2800,
      kind: "exterior",
    });
    expect(result.rebuild).toEqual({
      ok: false,
      fault: {
        code: "NotClosed",
        message: "room not closed",
        entityIds: [ctx.storeyId],
      },
    });
  });
});

describe("document reconstitution", () => {
  it("loads SceneIR back into FloorPlanDocument", () => {
    const doc = FloorPlanDocument.create({ id: "doc_x" });
    doc.addWall({
      storeyId: doc.storeys[0]!.id,
      start: PointMm.of(0, 0),
      end: PointMm.of(1000, 0),
      thickness: LengthMm.of(120),
      height: LengthMm.of(2800),
      kind: "interior",
    });
    const restored = FloorPlanDocument.fromSceneIR(doc.toSceneIR());
    expect(restored.storeys[0]?.walls).toHaveLength(1);
  });
});
