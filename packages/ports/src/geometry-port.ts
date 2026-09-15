export type FaultCode =
  | "NotManifold"
  | "InvalidGeometry"
  | "TooComplex"
  | "Cancelled"
  | "Timeout"
  | "NotClosed"
  | "OpeningOutOfBounds";

export interface GeometryFault {
  code: FaultCode;
  message: string;
  entityIds: readonly string[];
}

export interface MeshSolid {
  solidId: string;
  storeyId: string;
  kind: "wall" | "room" | "opening";
  entityId: string;
  nodeHint: string;
  verticesMm: readonly number[];
  indices: readonly number[];
}

export interface MeshProjection {
  solids: readonly MeshSolid[];
}

export interface FloorPlanSolidSemantics {
  documentId: string;
  revision: number;
  storeys: readonly {
    id: string;
    heightMm: number;
    elevationMm: number;
    walls: readonly {
      id: string;
      start: { x: number; y: number };
      end: { x: number; y: number };
      thicknessMm: number;
      heightMm: number;
      openings: readonly {
        id: string;
        widthMm: number;
        heightMm: number;
        offsetMm: number;
        sillHeightMm: number;
      }[];
    }[];
    rooms: readonly { id: string; wallIds: readonly string[] }[];
  }[];
}

export interface BuildRequest {
  documentRev: number;
  rebuildGeneration: number;
  dirty: boolean;
  semantics: FloorPlanSolidSemantics;
}

export type RebuildResult =
  | { ok: true; meshes: MeshProjection }
  | { ok: false; fault: GeometryFault };

export type GeometryStatus = "NoError" | "Fault" | "Dirty" | "Unknown";

export interface GeometryPort {
  rebuild(request: BuildRequest): Promise<RebuildResult>;
  ensureBuilt(
    documentRev: number,
    solidScope?: { storeyId?: string; solidId?: string },
  ): Promise<RebuildResult>;
  status(id: { solidId?: string; storeyId?: string }): Promise<GeometryStatus>;
  clearCache(keys?: readonly string[]): Promise<void>;
}
