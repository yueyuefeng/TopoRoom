import { describe, expect, it } from "vitest";
import { DomainError } from "./domain-error.js";
import { LengthMm } from "./length-mm.js";
import { PointMm } from "./point-mm.js";
import { Wall } from "./wall.js";

describe("Wall", () => {
  const start = PointMm.of(0, 0);
  const end = PointMm.of(4000, 0);

  it("records geometry, thickness, height and kind", () => {
    const wall = Wall.create({
      id: "wall_a",
      start,
      end,
      thickness: LengthMm.of(200),
      height: LengthMm.of(2800),
      kind: "exterior",
    });
    expect(wall.id).toBe("wall_a");
    expect(wall.lengthMm.value).toBe(4000);
    expect(wall.kind).toBe("exterior");
    expect(wall.openings).toEqual([]);
  });

  it("rejects a degenerate wall with zero length", () => {
    expect(() =>
      Wall.create({
        id: "wall_zero",
        start: PointMm.of(10, 10),
        end: PointMm.of(10, 10),
        thickness: LengthMm.of(200),
        height: LengthMm.of(2800),
        kind: "interior",
      }),
    ).toThrow(DomainError);
  });

  it("rejects non-positive thickness", () => {
    expect(() =>
      Wall.create({
        id: "wall_thin",
        start,
        end,
        thickness: LengthMm.of(0),
        height: LengthMm.of(2800),
        kind: "interior",
      }),
    ).toThrow(DomainError);
  });
});
