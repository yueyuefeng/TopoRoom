import type { GeometryFault, MeshProjection, RebuildResult } from "@toporoom/ports";

export class ExportRejectedError extends Error {
  constructor(readonly fault: GeometryFault) {
    super(`Export rejected: ${fault.code} ${fault.message}`);
    this.name = "ExportRejectedError";
  }
}

export class StatusGate {
  assertExportable(result: RebuildResult): MeshProjection {
    if (!result.ok) {
      throw new ExportRejectedError(result.fault);
    }
    return result.meshes;
  }
}
