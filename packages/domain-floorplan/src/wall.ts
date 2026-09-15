import { DomainError } from "./domain-error.js";
import type { WallKind } from "./kinds.js";
import { WALL_KINDS } from "./kinds.js";
import { LengthMm } from "./length-mm.js";
import { type Opening } from "./opening.js";
import { type PointMm } from "./point-mm.js";

export interface WallProps {
  id: string;
  start: PointMm;
  end: PointMm;
  thickness: LengthMm;
  height: LengthMm;
  kind: WallKind;
  openings?: readonly Opening[];
}

export class Wall {
  readonly id: string;
  readonly start: PointMm;
  readonly end: PointMm;
  readonly thickness: LengthMm;
  readonly height: LengthMm;
  readonly kind: WallKind;
  readonly openings: readonly Opening[];
  readonly lengthMm: LengthMm;

  private constructor(props: WallProps, openings: readonly Opening[]) {
    this.id = props.id;
    this.start = props.start;
    this.end = props.end;
    this.thickness = props.thickness;
    this.height = props.height;
    this.kind = props.kind;
    this.openings = openings;
    this.lengthMm = LengthMm.of(props.start.distanceTo(props.end));
  }

  static create(props: WallProps): Wall {
    if (!(WALL_KINDS as readonly string[]).includes(props.kind)) {
      throw new DomainError(`Unknown wall kind: ${props.kind}`, "INVALID_WALL");
    }
    const length = props.start.distanceTo(props.end);
    if (length <= 0) {
      throw new DomainError("Wall length must be positive", "INVALID_WALL");
    }
    if (props.thickness.value <= 0) {
      throw new DomainError("Wall thickness must be positive", "INVALID_WALL");
    }
    if (props.height.value <= 0) {
      throw new DomainError("Wall height must be positive", "INVALID_WALL");
    }
    const openings = props.openings ?? [];
    const wall = new Wall(props, openings);
    for (const opening of openings) {
      wall.assertOpeningFits(opening);
    }
    return wall;
  }

  hostOpening(opening: Opening): Wall {
    this.assertOpeningFits(opening);
    if (this.openings.some((existing) => existing.id === opening.id)) {
      throw new DomainError(
        `Opening ${opening.id} already hosted on wall ${this.id}`,
        "DUPLICATE_OPENING",
      );
    }
    return new Wall(this, [...this.openings, opening]);
  }

  replaceOpening(opening: Opening): Wall {
    const index = this.openings.findIndex((existing) => existing.id === opening.id);
    if (index < 0) {
      throw new DomainError(
        `Opening ${opening.id} is not hosted on wall ${this.id}`,
        "OPENING_NOT_FOUND",
      );
    }
    this.assertOpeningFits(opening);
    const next = [...this.openings];
    next[index] = opening;
    return new Wall(this, next);
  }

  private assertOpeningFits(opening: Opening): void {
    if (opening.offsetAlongWall.value < 0) {
      throw new DomainError(
        "Opening offset must not be negative",
        "OPENING_OUT_OF_BOUNDS",
      );
    }
    if (opening.occupiesUntilMm() > this.lengthMm.value + 1e-6) {
      throw new DomainError(
        "Opening extends past the host wall length",
        "OPENING_OUT_OF_BOUNDS",
      );
    }
    if (opening.sillHeight.value + opening.height.value > this.height.value + 1e-6) {
      throw new DomainError(
        "Opening is taller than the host wall",
        "OPENING_OUT_OF_BOUNDS",
      );
    }
  }
}
