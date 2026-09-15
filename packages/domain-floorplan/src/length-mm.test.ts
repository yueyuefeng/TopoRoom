import { describe, expect, it } from "vitest";
import { DomainError } from "./domain-error.js";
import { LengthMm } from "./length-mm.js";

describe("LengthMm", () => {
  it("accepts zero and positive millimetre values", () => {
    expect(LengthMm.of(0).value).toBe(0);
    expect(LengthMm.of(900).value).toBe(900);
  });

  it("rejects negative length", () => {
    expect(() => LengthMm.of(-1)).toThrow(DomainError);
    expect(() => LengthMm.of(-1)).toThrow(/negative/i);
  });

  it("rejects non-finite values", () => {
    expect(() => LengthMm.of(Number.NaN)).toThrow(DomainError);
    expect(() => LengthMm.of(Number.POSITIVE_INFINITY)).toThrow(DomainError);
  });

  it("is equal by value", () => {
    expect(LengthMm.of(120).equals(LengthMm.of(120))).toBe(true);
    expect(LengthMm.of(120).equals(LengthMm.of(121))).toBe(false);
  });
});
