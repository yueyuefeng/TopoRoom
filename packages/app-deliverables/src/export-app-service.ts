import type { SceneIR } from "@toporoom/domain-floorplan";
import {
  exportGltfJson,
  exportSceneGraph,
  type GltfJson,
  type SceneGraph,
} from "@toporoom/adapter-export-gltf";
import type { GeometryFault, GeometryPort, MeshProjection } from "@toporoom/ports";
import { semanticsFromSceneIR } from "@toporoom/ports";
import { ExportRejectedError, StatusGate } from "./status-gate.js";

export type ExportOutcome =
  | { ok: true; graph: SceneGraph; gltf: GltfJson; meshes: MeshProjection }
  | { ok: false; fault: GeometryFault };

export class ExportAppService {
  constructor(
    private readonly geometry: GeometryPort,
    private readonly gate = new StatusGate(),
  ) {}

  async exportSceneGraph(scene: SceneIR): Promise<ExportOutcome> {
    const rebuilt = await this.geometry.rebuild({
      documentRev: scene.revision,
      rebuildGeneration: 1,
      dirty: true,
      semantics: semanticsFromSceneIR(scene),
    });
    try {
      const meshes = this.gate.assertExportable(rebuilt);
      return {
        ok: true,
        graph: exportSceneGraph(scene, meshes),
        gltf: exportGltfJson(scene, meshes),
        meshes,
      };
    } catch (error) {
      if (error instanceof ExportRejectedError) {
        return { ok: false, fault: error.fault };
      }
      throw error;
    }
  }
}
