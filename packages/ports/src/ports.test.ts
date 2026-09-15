import { describe, expect, it } from "vitest";
import type { DepthStreamPort } from "./depth-stream-port.js";
import type { DocumentStorePort } from "./document-store-port.js";
import type { GeometryPort } from "./geometry-port.js";
import type { LaserRangefinderPort } from "./laser-rangefinder-port.js";
import type { NotifyPort } from "./notify-port.js";

describe("ports package", () => {
  it("exports interface-only contracts (compile-time shape)", () => {
    const geometry: GeometryPort | undefined = undefined;
    const laser: LaserRangefinderPort | undefined = undefined;
    const depth: DepthStreamPort | undefined = undefined;
    const store: DocumentStorePort | undefined = undefined;
    const notify: NotifyPort | undefined = undefined;
    expect(
      [geometry, laser, depth, store, notify].every((port) => port === undefined),
    ).toBe(true);
  });
});
