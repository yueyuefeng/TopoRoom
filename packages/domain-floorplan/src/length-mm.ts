import { DomainError } from "./domain-error.js";

export class LengthMm {
  private constructor(readonly value: number) {}

  static of(value: number): LengthMm {
    if (!Number.isFinite(value)) {
      throw new DomainError(
        "LengthMm must be a finite number of millimetres",
        "INVALID_LENGTH",
      );
    }
    if (value < 0) {
      throw new DomainError(
        "LengthMm must not be negative",
        "NEGATIVE_LENGTH",
      );
    }
    return new LengthMm(value);
  }

  static zero(): LengthMm {
    return new LengthMm(0);
  }

  equals(other: LengthMm): boolean {
    return this.value === other.value;
  }
}
