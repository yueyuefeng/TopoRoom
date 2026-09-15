export { DomainError } from "./domain-error.js";
export type { DomainEvent } from "./events.js";
export { FloorPlanDocument } from "./floor-plan-document.js";
export type {
  AddOpeningProps,
  AddWallProps,
  CloseRoomProps,
  CreateFloorPlanProps,
  SetMeasurementProps,
} from "./floor-plan-document.js";
export { LengthMm } from "./length-mm.js";
export {
  MEASUREMENT_SOURCES,
  isMeasurementSource,
} from "./measurement.js";
export type {
  MeasurementKind,
  MeasurementProps,
  MeasurementSource,
  MeasurementTarget,
} from "./measurement.js";
export { OPENING_KINDS, WALL_KINDS } from "./kinds.js";
export type { OpeningKind, WallKind } from "./kinds.js";
export { Opening } from "./opening.js";
export { PointMm } from "./point-mm.js";
export { Room } from "./room.js";
export {
  SCENE_IR_FORMAT,
  SCENE_IR_UNITS,
  SCENE_IR_VERSION,
} from "./scene-ir.js";
export type {
  SceneIR,
  SceneIRMeasurement,
  SceneIRMeta,
  SceneIROpening,
  SceneIRRoom,
  SceneIRStorey,
  SceneIRWall,
} from "./scene-ir.js";
export { Storey } from "./storey.js";
export { Wall } from "./wall.js";
