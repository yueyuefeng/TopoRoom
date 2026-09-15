import { DomainError } from "./domain-error.js";

export class PointMm {
  private constructor(
    readonly x: number,
    readonly y: number,
  ) {}

  static of(x: number, y: number): PointMm {
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      throw new DomainError(
        "PointMm coordinates must be finite millimetres",
        "INVALID_POINT",
      );
    }
    return new PointMm(x, y);
  }

  distanceTo(other: PointMm): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.hypot(dx, dy);
  }

  equals(other: PointMm, epsilon = 1e-6): boolean {
    return (
      Math.abs(this.x - other.x) <= epsilon &&
      Math.abs(this.y - other.y) <= epsilon
    );
  }
}
