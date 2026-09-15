import { DomainError } from "./domain-error.js";
import type { OpeningKind } from "./kinds.js";
import { OPENING_KINDS } from "./kinds.js";
import { type LengthMm } from "./length-mm.js";

export interface OpeningProps {
  id: string;
  kind: OpeningKind;
  width: LengthMm;
  height: LengthMm;
  offsetAlongWall: LengthMm;
  sillHeight: LengthMm;
}

export class Opening {
  readonly id: string;
  readonly kind: OpeningKind;
  readonly width: LengthMm;
  readonly height: LengthMm;
  readonly offsetAlongWall: LengthMm;
  readonly sillHeight: LengthMm;

  private constructor(props: OpeningProps) {
    this.id = props.id;
    this.kind = props.kind;
    this.width = props.width;
    this.height = props.height;
    this.offsetAlongWall = props.offsetAlongWall;
    this.sillHeight = props.sillHeight;
  }

  static create(props: OpeningProps): Opening {
    if (!(OPENING_KINDS as readonly string[]).includes(props.kind)) {
      throw new DomainError(
        `Unknown opening kind: ${props.kind}`,
        "INVALID_OPENING",
      );
    }
    if (props.width.value <= 0) {
      throw new DomainError("Opening width must be positive", "INVALID_OPENING");
    }
    if (props.height.value <= 0) {
      throw new DomainError(
        "Opening height must be positive",
        "INVALID_OPENING",
      );
    }
    return new Opening(props);
  }

  withWidth(width: LengthMm): Opening {
    return Opening.create({
      id: this.id,
      kind: this.kind,
      width,
      height: this.height,
      offsetAlongWall: this.offsetAlongWall,
      sillHeight: this.sillHeight,
    });
  }

  occupiesUntilMm(): number {
    return this.offsetAlongWall.value + this.width.value;
  }
}
