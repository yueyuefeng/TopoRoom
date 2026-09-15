import type { SceneIR } from "@toporoom/domain-floorplan";
import type { DocumentStorePort } from "../document-store-port.js";

export class InMemoryDocumentStore implements DocumentStorePort {
  private readonly docs = new Map<string, SceneIR>();

  async load(documentId: string): Promise<SceneIR | null> {
    const found = this.docs.get(documentId);
    return found ? structuredClone(found) : null;
  }

  async save(document: SceneIR): Promise<void> {
    this.docs.set(document.id, structuredClone(document));
  }
}
