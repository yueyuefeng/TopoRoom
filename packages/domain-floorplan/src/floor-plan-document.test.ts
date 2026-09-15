import { describe, expect, it } from "vitest";
import { DomainError } from "./domain-error.js";
import { FloorPlanDocument } from "./floor-plan-document.js";
import { LengthMm } from "./length-mm.js";
import { PointMm } from "./point-mm.js";

function rectangularRoomWalls() {
  return [
    {
      id: "wall_n",
      start: PointMm.of(0, 3000),
      end: PointMm.of(4000, 3000),
      thickness: LengthMm.of(200),
      height: LengthMm.of(2800),
      kind: "exterior" as const,
    },
    {
      id: "wall_e",
      start: PointMm.of(4000, 3000),
      end: PointMm.of(4000, 0),
      thickness: LengthMm.of(200),
      height: LengthMm.of(2800),
      kind: "exterior" as const,
    },
    {
      id: "wall_s",
      start: PointMm.of(4000, 0),
      end: PointMm.of(0, 0),
      thickness: LengthMm.of(200),
      height: LengthMm.of(2800),
      kind: "exterior" as const,
    },
    {
      id: "wall_w",
      start: PointMm.of(0, 0),
      end: PointMm.of(0, 3000),
      thickness: LengthMm.of(200),
      height: LengthMm.of(2800),
      kind: "exterior" as const,
    },
  ];
}

describe("FloorPlanDocument", () => {
  it("creates a SceneIR 0.1 document in millimetres with a default storey", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    expect(doc.format).toBe("toporoom.sceneir");
    expect(doc.version).toBe("0.1");
    expect(doc.units).toBe("mm");
    expect(doc.storeys).toHaveLength(1);
  });

  it("emits WallAdded when a wall is added", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
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
    const events = doc.pullDomainEvents();
    expect(events.map((e) => e.type)).toEqual([
      "WallAdded",
      "FloorPlanSemanticsChanged",
    ]);
    expect(events[0]).toMatchObject({
      type: "WallAdded",
      wallId: "wall_s",
      storeyId,
    });
  });

  it("emits OpeningAdded when a hosted opening is added", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
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
    doc.pullDomainEvents();
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
    const events = doc.pullDomainEvents();
    expect(events.map((e) => e.type)).toEqual([
      "OpeningAdded",
      "FloorPlanSemanticsChanged",
    ]);
    expect(events[0]).toMatchObject({
      type: "OpeningAdded",
      openingId: "op_door",
      wallId: "wall_s",
    });
  });

  it("emits RoomClosed when a closed wall loop is recorded", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    const storeyId = doc.storeys[0]!.id;
    for (const wall of rectangularRoomWalls()) {
      doc.addWall({ storeyId, ...wall });
    }
    doc.pullDomainEvents();
    doc.closeRoom({
      storeyId,
      id: "room_living",
      wallIds: ["wall_n", "wall_e", "wall_s", "wall_w"],
    });
    const events = doc.pullDomainEvents();
    expect(events.map((e) => e.type)).toEqual([
      "RoomClosed",
      "FloorPlanSemanticsChanged",
    ]);
    expect(events[0]).toMatchObject({
      type: "RoomClosed",
      roomId: "room_living",
      wallIds: ["wall_n", "wall_e", "wall_s", "wall_w"],
    });
  });

  it("rejects closing a room that is not a closed loop", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    const storeyId = doc.storeys[0]!.id;
    doc.addWall({ storeyId, ...rectangularRoomWalls()[0]! });
    doc.addWall({ storeyId, ...rectangularRoomWalls()[1]! });
    expect(() =>
      doc.closeRoom({
        storeyId,
        id: "room_open",
        wallIds: ["wall_n", "wall_e"],
      }),
    ).toThrow(DomainError);
  });

  it("round-trips through SceneIR 0.1", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    const storeyId = doc.storeys[0]!.id;
    for (const wall of rectangularRoomWalls()) {
      doc.addWall({ storeyId, ...wall });
    }
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
    doc.closeRoom({
      storeyId,
      id: "room_living",
      wallIds: ["wall_n", "wall_e", "wall_s", "wall_w"],
    });
    const snapshot = doc.toSceneIR();
    const restored = FloorPlanDocument.fromSceneIR(snapshot);
    expect(restored.toSceneIR()).toEqual(snapshot);
    expect(snapshot.format).toBe("toporoom.sceneir");
    expect(snapshot.version).toBe("0.1");
    expect(snapshot.units).toBe("mm");
  });
});
