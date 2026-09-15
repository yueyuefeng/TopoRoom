import type {
  BuildRequest,
  FloorPlanSolidSemantics,
  GeometryFault,
  GeometryPort,
  GeometryStatus,
  MeshProjection,
  RebuildResult,
} from "../geometry-port.js";
import { semanticsFromSceneIR } from "../semantics.js";

export { semanticsFromSceneIR };

export class FakeGeometryPort implements GeometryPort {
  private mode: "ok" | "fault" = "ok";
  private fault: GeometryFault = {
    code: "NotManifold",
    message: "synthetic fault",
    entityIds: [],
  };
  private lastRequest: BuildRequest | undefined;
  private lastStatus: GeometryStatus = "Unknown";

  failWith(fault: GeometryFault): void {
    this.mode = "fault";
    this.fault = fault;
    this.lastStatus = "Fault";
  }

  succeed(): void {
    this.mode = "ok";
    this.lastStatus = "NoError";
  }

  get lastBuildRequest(): BuildRequest | undefined {
    return this.lastRequest;
  }

  async rebuild(request: BuildRequest): Promise<RebuildResult> {
    this.lastRequest = request;
    if (this.mode === "fault") {
      this.lastStatus = "Fault";
      return { ok: false, fault: this.fault };
    }
    this.lastStatus = "NoError";
    return { ok: true, meshes: projectSemantics(request.semantics) };
  }

  async ensureBuilt(documentRev: number): Promise<RebuildResult> {
    if (!this.lastRequest) {
      return {
        ok: false,
        fault: {
          code: "InvalidGeometry",
          message: `nothing built for revision ${documentRev}`,
          entityIds: [],
        },
      };
    }
    return this.rebuild(this.lastRequest);
  }

  async status(): Promise<GeometryStatus> {
    return this.lastStatus;
  }

  async clearCache(): Promise<void> {
    this.lastRequest = undefined;
    this.lastStatus = "Unknown";
  }
}

export function projectSemantics(
  semantics: FloorPlanSolidSemantics,
): MeshProjection {
  const solids = [];
  for (const storey of semantics.storeys) {
    for (const wall of storey.walls) {
      solids.push({
        solidId: `solid_${wall.id}`,
        storeyId: storey.id,
        kind: "wall" as const,
        entityId: wall.id,
        nodeHint: `Wall_${wall.id}`,
        verticesMm: boxVertices(wall.start.x, wall.start.y, wall.end.x, wall.end.y, storey.heightMm),
        indices: BOX_INDICES,
      });
      for (const opening of wall.openings) {
        solids.push({
          solidId: `solid_${opening.id}`,
          storeyId: storey.id,
          kind: "opening" as const,
          entityId: opening.id,
          nodeHint: `Opening_${opening.id}`,
          verticesMm: [],
          indices: [],
        });
      }
    }
    for (const room of storey.rooms) {
      solids.push({
        solidId: `solid_${room.id}`,
        storeyId: storey.id,
        kind: "room" as const,
        entityId: room.id,
        nodeHint: `Room_${room.id}`,
        verticesMm: [],
        indices: [],
      });
    }
  }
  return { solids };
}

const BOX_INDICES = [0, 1, 2, 0, 2, 3];

function boxVertices(
  x0: number,
  y0: number,
  x1: number,
  y1: number,
  heightMm: number,
): number[] {
  return [x0, 0, y0, x1, 0, y1, x1, heightMm, y1, x0, heightMm, y0];
}
