import { describe, expect, it } from "vitest";
import { DomainError } from "./domain-error.js";
import { LengthMm } from "./length-mm.js";
import { Opening } from "./opening.js";
import { PointMm } from "./point-mm.js";
import { Wall } from "./wall.js";

function hostWall() {
  return Wall.create({
    id: "wall_host",
    start: PointMm.of(0, 0),
    end: PointMm.of(4000, 0),
    thickness: LengthMm.of(200),
    height: LengthMm.of(2800),
    kind: "exterior",
  });
}

describe("Opening", () => {
  it("places a rectangular door on a host wall", () => {
    const opening = Opening.create({
      id: "op_door",
      kind: "door",
      width: LengthMm.of(900),
      height: LengthMm.of(2100),
      offsetAlongWall: LengthMm.of(500),
      sillHeight: LengthMm.of(0),
    });
    const wall = hostWall().hostOpening(opening);
    expect(wall.openings).toHaveLength(1);
    expect(wall.openings[0]?.id).toBe("op_door");
  });

  it("rejects an opening that extends past the wall length", () => {
    const opening = Opening.create({
      id: "op_wide",
      kind: "door",
      width: LengthMm.of(2000),
      height: LengthMm.of(2100),
      offsetAlongWall: LengthMm.of(2500),
      sillHeight: LengthMm.of(0),
    });
    expect(() => hostWall().hostOpening(opening)).toThrow(DomainError);
  });

  it("rejects an opening taller than the host wall", () => {
    const opening = Opening.create({
      id: "op_tall",
      kind: "window",
      width: LengthMm.of(900),
      height: LengthMm.of(3000),
      offsetAlongWall: LengthMm.of(200),
      sillHeight: LengthMm.of(900),
    });
    expect(() => hostWall().hostOpening(opening)).toThrow(DomainError);
  });

  it("rejects non-positive opening width", () => {
    expect(() =>
      Opening.create({
        id: "op_zero",
        kind: "door",
        width: LengthMm.of(0),
        height: LengthMm.of(2100),
        offsetAlongWall: LengthMm.of(0),
        sillHeight: LengthMm.of(0),
      }),
    ).toThrow(DomainError);
  });
});
