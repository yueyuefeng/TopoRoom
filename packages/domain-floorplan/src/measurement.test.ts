import { describe, expect, it } from "vitest";
import { DomainError } from "./domain-error.js";
import { FloorPlanDocument } from "./floor-plan-document.js";
import { LengthMm } from "./length-mm.js";
import { MEASUREMENT_SOURCES } from "./measurement.js";
import { PointMm } from "./point-mm.js";

describe("measurements", () => {
  it("freezes SceneIR 0.1 sources to laser | typed | depth_fit", () => {
    expect([...MEASUREMENT_SOURCES].sort()).toEqual([
      "depth_fit",
      "laser",
      "typed",
    ]);
  });

  it("records a laser length on an opening without dropping source", () => {
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
    doc.addOpening({
      storeyId,
      wallId: "wall_s",
      id: "op_door",
      kind: "door",
      width: LengthMm.of(800),
      height: LengthMm.of(2100),
      offsetAlongWall: LengthMm.of(800),
      sillHeight: LengthMm.of(0),
    });
    doc.setMeasurement({
      id: "m_door_width",
      kind: "length",
      value: LengthMm.of(900),
      source: "laser",
      instrumentId: "laser_sku_x",
      target: { entityType: "opening", entityId: "op_door", field: "width" },
    });
    const measurement = doc.measurements.find((m) => m.id === "m_door_width");
    expect(measurement?.source).toBe("laser");
    expect(measurement?.valueMm).toBe(900);
    expect(
      doc.storeys[0]?.walls
        .find((w) => w.id === "wall_s")
        ?.openings.find((o) => o.id === "op_door")?.width.value,
    ).toBe(900);
  });

  it("rejects an unknown measurement source", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    expect(() =>
      doc.setMeasurement({
        id: "m_bad",
        kind: "length",
        value: LengthMm.of(1000),
        source: "rf_ble" as "laser",
      }),
    ).toThrow(DomainError);
  });

  it("does not let depth_fit silently overwrite a laser measurement", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    doc.setMeasurement({
      id: "m_axis",
      kind: "length",
      value: LengthMm.of(4000),
      source: "laser",
      instrumentId: "laser_sku_x",
      between: ["lm_a", "lm_b"],
    });
    expect(() =>
      doc.setMeasurement({
        id: "m_axis",
        kind: "length",
        value: LengthMm.of(4012),
        source: "depth_fit",
      }),
    ).toThrow(/laser/i);
    expect(doc.measurements[0]?.source).toBe("laser");
    expect(doc.measurements[0]?.valueMm).toBe(4000);
  });

  it("allows typed to replace a previous typed value", () => {
    const doc = FloorPlanDocument.create({ id: "doc_1" });
    doc.setMeasurement({
      id: "m_height",
      kind: "length",
      value: LengthMm.of(2700),
      source: "typed",
      target: {
        entityType: "storey",
        entityId: doc.storeys[0]!.id,
        field: "height",
      },
    });
    doc.setMeasurement({
      id: "m_height",
      kind: "length",
      value: LengthMm.of(2800),
      source: "typed",
      target: {
        entityType: "storey",
        entityId: doc.storeys[0]!.id,
        field: "height",
      },
    });
    expect(doc.measurements[0]?.valueMm).toBe(2800);
    expect(doc.storeys[0]?.height.value).toBe(2800);
  });
});
