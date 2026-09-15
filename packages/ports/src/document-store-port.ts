import type { SceneIR } from "@toporoom/domain-floorplan";

export interface DocumentStorePort {
  load(documentId: string): Promise<SceneIR | null>;
  save(document: SceneIR): Promise<void>;
}
