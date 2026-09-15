import type { DomainEvent, SceneIR } from "@toporoom/domain-floorplan";
import { FloorPlanDocument } from "@toporoom/domain-floorplan";
import type { DocumentStorePort, RebuildResult } from "@toporoom/ports";
import type { GeometryRebuildPolicy } from "./rebuild-policy.js";

export class DocumentNotFoundError extends Error {
  constructor(documentId: string) {
    super(`Document ${documentId} not found`);
    this.name = "DocumentNotFoundError";
  }
}

export interface CommandResult {
  scene: SceneIR;
  events: DomainEvent[];
  rebuild: RebuildResult;
}

export async function loadDocument(
  store: DocumentStorePort,
  documentId: string,
): Promise<FloorPlanDocument> {
  const scene = await store.load(documentId);
  if (!scene) {
    throw new DocumentNotFoundError(documentId);
  }
  return FloorPlanDocument.fromSceneIR(scene);
}

export async function commit(
  store: DocumentStorePort,
  rebuild: GeometryRebuildPolicy,
  document: FloorPlanDocument,
): Promise<CommandResult> {
  const events = document.pullDomainEvents();
  const scene = document.toSceneIR();
  await store.save(scene);
  const result = await rebuild.onSemanticsChanged(scene);
  return { scene, events, rebuild: result };
}
