import type { SceneIR } from "@toporoom/domain-floorplan";
import type { GeometryPort, RebuildResult } from "@toporoom/ports";
import { semanticsFromSceneIR } from "@toporoom/ports";

export class GeometryRebuildPolicy {
  private generation = 0;

  constructor(private readonly geometry: GeometryPort) {}

  async onSemanticsChanged(scene: SceneIR): Promise<RebuildResult> {
    this.generation += 1;
    return this.geometry.rebuild({
      documentRev: scene.revision,
      rebuildGeneration: this.generation,
      dirty: true,
      semantics: semanticsFromSceneIR(scene),
    });
  }
}
