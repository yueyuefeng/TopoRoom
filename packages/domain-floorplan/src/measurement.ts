import type { OpeningKind, WallKind } from "./kinds.js";
import { OPENING_KINDS, WALL_KINDS } from "./kinds.js";

export { OPENING_KINDS, WALL_KINDS };
export type { OpeningKind, WallKind };

export const MEASUREMENT_SOURCES = ["laser", "typed", "depth_fit"] as const;
export type MeasurementSource = (typeof MEASUREMENT_SOURCES)[number];

export type MeasurementKind = "length";

export interface MeasurementTarget {
  entityType: "wall" | "opening" | "storey";
  entityId: string;
  field: string;
}

export interface MeasurementProps {
  id: string;
  kind: MeasurementKind;
  valueMm: number;
  source: MeasurementSource;
  instrumentId?: string;
  between?: readonly string[];
  target?: MeasurementTarget;
}

export function isMeasurementSource(value: string): value is MeasurementSource {
  return (MEASUREMENT_SOURCES as readonly string[]).includes(value);
}
