import type { DomainEvent } from "./events.js";
import { DomainError } from "./domain-error.js";
import type { WallKind } from "./kinds.js";
import { LengthMm } from "./length-mm.js";
import type {
  MeasurementKind,
  MeasurementProps,
  MeasurementSource,
  MeasurementTarget,
} from "./measurement.js";
import { isMeasurementSource } from "./measurement.js";
import type { OpeningKind } from "./kinds.js";
import { Opening } from "./opening.js";
import { PointMm } from "./point-mm.js";
import { Room } from "./room.js";
import type { SceneIR, SceneIRMeasurement } from "./scene-ir.js";
import {
  SCENE_IR_FORMAT,
  SCENE_IR_UNITS,
  SCENE_IR_VERSION,
} from "./scene-ir.js";
import { Storey } from "./storey.js";
import { Wall } from "./wall.js";

const DEFAULT_STOREY_ID = "storey_1";
const DEFAULT_STOREY_HEIGHT_MM = 2800;

export interface CreateFloorPlanProps {
  id: string;
  storeyId?: string;
  storeyHeight?: LengthMm;
  storeyElevation?: LengthMm;
}

export interface AddWallProps {
  storeyId: string;
  id?: string;
  start: PointMm;
  end: PointMm;
  thickness: LengthMm;
  height: LengthMm;
  kind: WallKind;
}

export interface AddOpeningProps {
  storeyId: string;
  wallId: string;
  id?: string;
  kind: OpeningKind;
  width: LengthMm;
  height: LengthMm;
  offsetAlongWall: LengthMm;
  sillHeight: LengthMm;
}

export interface CloseRoomProps {
  storeyId: string;
  id: string;
  wallIds: readonly string[];
}

export interface SetMeasurementProps {
  id: string;
  kind: MeasurementKind;
  value: LengthMm;
  source: MeasurementSource;
  instrumentId?: string;
  between?: readonly string[];
  target?: MeasurementTarget;
}

export class FloorPlanDocument {
  readonly format = SCENE_IR_FORMAT;
  readonly version = SCENE_IR_VERSION;
  readonly units = SCENE_IR_UNITS;
  readonly id: string;
  private _revision: number;
  private _storeys: Storey[];
  private _measurements: MeasurementProps[];
  private events: DomainEvent[] = [];
  private seq = 0;

  private constructor(params: {
    id: string;
    revision: number;
    storeys: Storey[];
    measurements: MeasurementProps[];
  }) {
    this.id = params.id;
    this._revision = params.revision;
    this._storeys = params.storeys;
    this._measurements = params.measurements;
  }

  static create(props: CreateFloorPlanProps): FloorPlanDocument {
    const storey = Storey.create({
      id: props.storeyId ?? DEFAULT_STOREY_ID,
      elevation: props.storeyElevation ?? LengthMm.zero(),
      height: props.storeyHeight ?? LengthMm.of(DEFAULT_STOREY_HEIGHT_MM),
    });
    return new FloorPlanDocument({
      id: props.id,
      revision: 0,
      storeys: [storey],
      measurements: [],
    });
  }

  static fromSceneIR(scene: SceneIR): FloorPlanDocument {
    if (scene.format !== SCENE_IR_FORMAT) {
      throw new DomainError(
        `Unsupported SceneIR format: ${scene.format}`,
        "INVALID_SCENEIR",
      );
    }
    if (scene.version !== SCENE_IR_VERSION) {
      throw new DomainError(
        `Unsupported SceneIR version: ${scene.version}`,
        "INVALID_SCENEIR",
      );
    }
    if (scene.units !== SCENE_IR_UNITS) {
      throw new DomainError(
        `SceneIR units must be mm, got ${scene.units}`,
        "INVALID_SCENEIR",
      );
    }
    const storeys = scene.storeys.map((storey) =>
      Storey.create({
        id: storey.id,
        elevation: LengthMm.of(storey.elevationMm),
        height: LengthMm.of(storey.heightMm),
        walls: storey.walls.map((wall) =>
          Wall.create({
            id: wall.id,
            kind: wall.kind,
            start: PointMm.of(wall.start.x, wall.start.y),
            end: PointMm.of(wall.end.x, wall.end.y),
            thickness: LengthMm.of(wall.thicknessMm),
            height: LengthMm.of(wall.heightMm),
            openings: wall.openings.map((opening) =>
              Opening.create({
                id: opening.id,
                kind: opening.kind,
                width: LengthMm.of(opening.widthMm),
                height: LengthMm.of(opening.heightMm),
                offsetAlongWall: LengthMm.of(opening.offsetMm),
                sillHeight: LengthMm.of(opening.sillHeightMm),
              }),
            ),
          }),
        ),
        rooms: storey.rooms.map((room) => new Room(room.id, room.wallIds)),
      }),
    );
    return new FloorPlanDocument({
      id: scene.id,
      revision: scene.revision,
      storeys,
      measurements: scene.measurements.map(cloneMeasurement),
    });
  }

  get revision(): number {
    return this._revision;
  }

  get storeys(): readonly Storey[] {
    return this._storeys;
  }

  get measurements(): readonly MeasurementProps[] {
    return this._measurements;
  }

  addWall(props: AddWallProps): Wall {
    const storey = this.requireStorey(props.storeyId);
    const wall = Wall.create({
      id: props.id ?? this.nextId("wall"),
      start: props.start,
      end: props.end,
      thickness: props.thickness,
      height: props.height,
      kind: props.kind,
    });
    this.replaceStorey(storey.addWall(wall));
    this.record({
      type: "WallAdded",
      documentId: this.id,
      storeyId: props.storeyId,
      wallId: wall.id,
    });
    this.bumpSemantics();
    return wall;
  }

  addOpening(props: AddOpeningProps): Opening {
    const storey = this.requireStorey(props.storeyId);
    const opening = Opening.create({
      id: props.id ?? this.nextId("opening"),
      kind: props.kind,
      width: props.width,
      height: props.height,
      offsetAlongWall: props.offsetAlongWall,
      sillHeight: props.sillHeight,
    });
    this.replaceStorey(storey.hostOpening(props.wallId, opening));
    this.record({
      type: "OpeningAdded",
      documentId: this.id,
      storeyId: props.storeyId,
      wallId: props.wallId,
      openingId: opening.id,
    });
    this.bumpSemantics();
    return opening;
  }

  closeRoom(props: CloseRoomProps): void {
    const storey = this.requireStorey(props.storeyId);
    this.replaceStorey(storey.closeRoom(props.id, props.wallIds));
    this.record({
      type: "RoomClosed",
      documentId: this.id,
      storeyId: props.storeyId,
      roomId: props.id,
      wallIds: [...props.wallIds],
    });
    this.bumpSemantics();
  }

  setMeasurement(props: SetMeasurementProps): MeasurementProps {
    if (!isMeasurementSource(props.source)) {
      throw new DomainError(
        `Unknown measurement source: ${String(props.source)}`,
        "INVALID_MEASUREMENT_SOURCE",
      );
    }
    const next: MeasurementProps = {
      id: props.id,
      kind: props.kind,
      valueMm: props.value.value,
      source: props.source,
      ...(props.instrumentId ? { instrumentId: props.instrumentId } : {}),
      ...(props.between ? { between: [...props.between] } : {}),
      ...(props.target ? { target: props.target } : {}),
    };
    const existingIndex = this._measurements.findIndex((m) => m.id === props.id);
    if (existingIndex >= 0) {
      const existing = this._measurements[existingIndex]!;
      assertMeasurementMayReplace(existing, next);
      this._measurements[existingIndex] = next;
    } else {
      this._measurements.push(next);
    }
    this.applyMeasurementTarget(next);
    this.bumpSemantics();
    return next;
  }

  toSceneIR(): SceneIR {
    return {
      format: this.format,
      version: this.version,
      id: this.id,
      units: this.units,
      revision: this._revision,
      storeys: this._storeys.map((storey) => ({
        id: storey.id,
        elevationMm: storey.elevation.value,
        heightMm: storey.height.value,
        walls: storey.walls.map((wall) => ({
          id: wall.id,
          kind: wall.kind,
          start: { x: wall.start.x, y: wall.start.y },
          end: { x: wall.end.x, y: wall.end.y },
          thicknessMm: wall.thickness.value,
          heightMm: wall.height.value,
          openings: wall.openings.map((opening) => ({
            id: opening.id,
            kind: opening.kind,
            widthMm: opening.width.value,
            heightMm: opening.height.value,
            offsetMm: opening.offsetAlongWall.value,
            sillHeightMm: opening.sillHeight.value,
          })),
        })),
        rooms: storey.rooms.map((room) => ({
          id: room.id,
          wallIds: [...room.wallIds],
        })),
      })),
      measurements: this._measurements.map(cloneMeasurement),
    };
  }

  pullDomainEvents(): DomainEvent[] {
    const pending = this.events;
    this.events = [];
    return pending;
  }

  private applyMeasurementTarget(measurement: MeasurementProps): void {
    const target = measurement.target;
    if (!target) {
      return;
    }
    if (target.entityType === "opening" && target.field === "width") {
      this.resizeOpening(target.entityId, LengthMm.of(measurement.valueMm));
      return;
    }
    if (target.entityType === "storey" && target.field === "height") {
      const storey = this.requireStorey(target.entityId);
      this.replaceStorey(storey.withHeight(LengthMm.of(measurement.valueMm)));
      this.record({
        type: "StoreyHeightChanged",
        documentId: this.id,
        storeyId: storey.id,
        heightMm: measurement.valueMm,
      });
    }
  }

  private resizeOpening(openingId: string, width: LengthMm): void {
    for (const storey of this._storeys) {
      for (const wall of storey.walls) {
        const opening = wall.openings.find((candidate) => candidate.id === openingId);
        if (!opening) {
          continue;
        }
        this.replaceStorey(storey.replaceWall(wall.replaceOpening(opening.withWidth(width))));
        return;
      }
    }
    throw new DomainError(`Opening ${openingId} not found`, "OPENING_NOT_FOUND");
  }

  private requireStorey(storeyId: string): Storey {
    const storey = this._storeys.find((candidate) => candidate.id === storeyId);
    if (!storey) {
      throw new DomainError(`Storey ${storeyId} not found`, "STOREY_NOT_FOUND");
    }
    return storey;
  }

  private replaceStorey(storey: Storey): void {
    const index = this._storeys.findIndex((candidate) => candidate.id === storey.id);
    if (index < 0) {
      throw new DomainError(`Storey ${storey.id} not found`, "STOREY_NOT_FOUND");
    }
    this._storeys[index] = storey;
  }

  private bumpSemantics(): void {
    this._revision += 1;
    this.record({
      type: "FloorPlanSemanticsChanged",
      documentId: this.id,
      revision: this._revision,
    });
  }

  private record(event: DomainEvent): void {
    this.events.push(event);
  }

  private nextId(prefix: string): string {
    this.seq += 1;
    return `${prefix}_${this.seq}`;
  }
}

function cloneMeasurement(measurement: SceneIRMeasurement): MeasurementProps {
  return {
    id: measurement.id,
    kind: measurement.kind,
    valueMm: measurement.valueMm,
    source: measurement.source,
    ...(measurement.instrumentId
      ? { instrumentId: measurement.instrumentId }
      : {}),
    ...(measurement.between ? { between: [...measurement.between] } : {}),
    ...(measurement.target ? { target: { ...measurement.target } } : {}),
  };
}

function assertMeasurementMayReplace(
  existing: MeasurementProps,
  next: MeasurementProps,
): void {
  if (existing.source === "laser" && next.source === "depth_fit") {
    throw new DomainError(
      "depth_fit must not silently overwrite a laser measurement",
      "MEASUREMENT_SOURCE_LOCKED",
    );
  }
  if (existing.source === "typed" && next.source === "depth_fit") {
    throw new DomainError(
      "depth_fit must not silently overwrite a typed measurement",
      "MEASUREMENT_SOURCE_LOCKED",
    );
  }
}
