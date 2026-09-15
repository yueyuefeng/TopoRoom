import { DomainError } from "./domain-error.js";
import { type LengthMm } from "./length-mm.js";
import { type Opening } from "./opening.js";
import { type PointMm } from "./point-mm.js";
import { Room } from "./room.js";
import { type Wall } from "./wall.js";

export interface StoreyProps {
  id: string;
  elevation: LengthMm;
  height: LengthMm;
  walls?: readonly Wall[];
  rooms?: readonly Room[];
}

export class Storey {
  readonly id: string;
  readonly elevation: LengthMm;
  readonly height: LengthMm;
  readonly walls: readonly Wall[];
  readonly rooms: readonly Room[];

  private constructor(props: StoreyProps) {
    this.id = props.id;
    this.elevation = props.elevation;
    this.height = props.height;
    this.walls = props.walls ?? [];
    this.rooms = props.rooms ?? [];
  }

  static create(props: StoreyProps): Storey {
    if (props.height.value <= 0) {
      throw new DomainError("Storey height must be positive", "INVALID_STOREY");
    }
    return new Storey(props);
  }

  addWall(wall: Wall): Storey {
    if (this.walls.some((existing) => existing.id === wall.id)) {
      throw new DomainError(`Wall ${wall.id} already exists`, "DUPLICATE_WALL");
    }
    return new Storey({
      id: this.id,
      elevation: this.elevation,
      height: this.height,
      walls: [...this.walls, wall],
      rooms: this.rooms,
    });
  }

  wallById(wallId: string): Wall {
    const wall = this.walls.find((candidate) => candidate.id === wallId);
    if (!wall) {
      throw new DomainError(`Wall ${wallId} not found`, "WALL_NOT_FOUND");
    }
    return wall;
  }

  hostOpening(wallId: string, opening: Opening): Storey {
    const wall = this.wallById(wallId);
    return this.replaceWall(wall.hostOpening(opening));
  }

  replaceWall(wall: Wall): Storey {
    const index = this.walls.findIndex((candidate) => candidate.id === wall.id);
    if (index < 0) {
      throw new DomainError(`Wall ${wall.id} not found`, "WALL_NOT_FOUND");
    }
    const walls = [...this.walls];
    walls[index] = wall;
    return new Storey({
      id: this.id,
      elevation: this.elevation,
      height: this.height,
      walls,
      rooms: this.rooms,
    });
  }

  withHeight(height: LengthMm): Storey {
    return Storey.create({
      id: this.id,
      elevation: this.elevation,
      height,
      walls: this.walls,
      rooms: this.rooms,
    });
  }

  closeRoom(id: string, wallIds: readonly string[]): Storey {
    if (this.rooms.some((room) => room.id === id)) {
      throw new DomainError(`Room ${id} already exists`, "DUPLICATE_ROOM");
    }
    this.assertClosedLoop(wallIds);
    return new Storey({
      id: this.id,
      elevation: this.elevation,
      height: this.height,
      walls: this.walls,
      rooms: [...this.rooms, new Room(id, wallIds)],
    });
  }

  private assertClosedLoop(wallIds: readonly string[]): void {
    if (wallIds.length < 3) {
      throw new DomainError(
        "A closed room needs at least three walls",
        "ROOM_NOT_CLOSED",
      );
    }
    const unique = new Set(wallIds);
    if (unique.size !== wallIds.length) {
      throw new DomainError("Room walls must be unique", "ROOM_NOT_CLOSED");
    }
    const walls = wallIds.map((wallId) => this.wallById(wallId));
    for (let i = 0; i < walls.length; i += 1) {
      const current = walls[i]!;
      const next = walls[(i + 1) % walls.length]!;
      const sharesEndpoint =
        current.end.equals(next.start) ||
        current.end.equals(next.end) ||
        current.start.equals(next.start) ||
        current.start.equals(next.end);
      if (!sharesEndpoint) {
        throw new DomainError(
          `Walls ${current.id} and ${next.id} do not share an endpoint`,
          "ROOM_NOT_CLOSED",
        );
      }
    }
    const endpoints = new Map<string, number>();
    const key = (p: PointMm) => `${p.x},${p.y}`;
    for (const wall of walls) {
      endpoints.set(key(wall.start), (endpoints.get(key(wall.start)) ?? 0) + 1);
      endpoints.set(key(wall.end), (endpoints.get(key(wall.end)) ?? 0) + 1);
    }
    for (const degree of endpoints.values()) {
      if (degree !== 2) {
        throw new DomainError(
          "Room walls must form a single closed loop",
          "ROOM_NOT_CLOSED",
        );
      }
    }
  }
}
