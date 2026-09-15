import { LengthMm } from "@toporoom/domain-floorplan";
import type { OpeningKind } from "@toporoom/domain-floorplan";
import type { DocumentStorePort } from "@toporoom/ports";
import { commit, loadDocument, type CommandResult } from "./document-io.js";
import type { GeometryRebuildPolicy } from "./rebuild-policy.js";

export interface AddOpeningCommand {
  documentId: string;
  storeyId: string;
  wallId: string;
  openingId?: string;
  kind: OpeningKind;
  widthMm: number;
  heightMm: number;
  offsetMm: number;
  sillHeightMm: number;
}

export class AddOpeningHandler {
  constructor(
    private readonly store: DocumentStorePort,
    private readonly rebuild: GeometryRebuildPolicy,
  ) {}

  async execute(command: AddOpeningCommand): Promise<CommandResult> {
    const document = await loadDocument(this.store, command.documentId);
    document.addOpening({
      storeyId: command.storeyId,
      wallId: command.wallId,
      id: command.openingId,
      kind: command.kind,
      width: LengthMm.of(command.widthMm),
      height: LengthMm.of(command.heightMm),
      offsetAlongWall: LengthMm.of(command.offsetMm),
      sillHeight: LengthMm.of(command.sillHeightMm),
    });
    return commit(this.store, this.rebuild, document);
  }
}
