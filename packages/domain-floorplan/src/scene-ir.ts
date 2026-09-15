import type { MeasurementProps } from "./measurement.js";
import type { OpeningKind, WallKind } from "./kinds.js";

export const SCENE_IR_FORMAT = "toporoom.sceneir" as const;
export const SCENE_IR_VERSION = "0.1" as const;
export const SCENE_IR_UNITS = "mm" as const;

export interface SceneIR {
  format: typeof SCENE_IR_FORMAT;
  version: typeof SCENE_IR_VERSION;
  id: string;
  units: typeof SCENE_IR_UNITS;
  revision: number;
  meta?: SceneIRMeta;
  storeys: SceneIRStorey[];
  measurements: SceneIRMeasurement[];
}

export interface SceneIRMeta {
  accessoryFirmware?: string;
  moduleSku?: string;
  experimental?: boolean;
}

export interface SceneIRStorey {
  id: string;
  elevationMm: number;
  heightMm: number;
  walls: SceneIRWall[];
  rooms: SceneIRRoom[];
}

export interface SceneIRWall {
  id: string;
  kind: WallKind;
  start: { x: number; y: number };
  end: { x: number; y: number };
  thicknessMm: number;
  heightMm: number;
  openings: SceneIROpening[];
}

export interface SceneIROpening {
  id: string;
  kind: OpeningKind;
  widthMm: number;
  heightMm: number;
  offsetMm: number;
  sillHeightMm: number;
}

export interface SceneIRRoom {
  id: string;
  wallIds: string[];
}

export type SceneIRMeasurement = MeasurementProps;
