import { LengthMm, PointMm } from "@toporoom/domain-floorplan";
import type { WallKind } from "@toporoom/domain-floorplan";
import type { DocumentStorePort } from "@toporoom/ports";
import { commit, loadDocument, type CommandResult } from "./document-io.js";
import type { GeometryRebuildPolicy } from "./rebuild-policy.js";

export interface AddWallCommand {
  documentId: string;
  storeyId: string;
  wallId?: string;
  start: { x: number; y: number };
  end: { x: number; y: number };
  thicknessMm: number;
  heightMm: number;
  kind: WallKind;
}

export class AddWallHandler {
  constructor(
    private readonly store: DocumentStorePort,
    private readonly rebuild: GeometryRebuildPolicy,
  ) {}

  async execute(command: AddWallCommand): Promise<CommandResult> {
    const document = await loadDocument(this.store, command.documentId);
    document.addWall({
      storeyId: command.storeyId,
      id: command.wallId,
      start: PointMm.of(command.start.x, command.start.y),
      end: PointMm.of(command.end.x, command.end.y),
      thickness: LengthMm.of(command.thicknessMm),
      height: LengthMm.of(command.heightMm),
      kind: command.kind,
    });
    return commit(this.store, this.rebuild, document);
  }
}
