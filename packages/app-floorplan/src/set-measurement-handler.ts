import { LengthMm } from "@toporoom/domain-floorplan";
import type {
  MeasurementKind,
  MeasurementSource,
  MeasurementTarget,
} from "@toporoom/domain-floorplan";
import type { DocumentStorePort } from "@toporoom/ports";
import { commit, loadDocument, type CommandResult } from "./document-io.js";
import type { GeometryRebuildPolicy } from "./rebuild-policy.js";

export interface SetMeasurementCommand {
  documentId: string;
  measurementId: string;
  kind: MeasurementKind;
  valueMm: number;
  source: MeasurementSource;
  instrumentId?: string;
  between?: readonly string[];
  target?: MeasurementTarget;
}

export class SetMeasurementHandler {
  constructor(
    private readonly store: DocumentStorePort,
    private readonly rebuild: GeometryRebuildPolicy,
  ) {}

  async execute(command: SetMeasurementCommand): Promise<CommandResult> {
    const document = await loadDocument(this.store, command.documentId);
    document.setMeasurement({
      id: command.measurementId,
      kind: command.kind,
      value: LengthMm.of(command.valueMm),
      source: command.source,
      instrumentId: command.instrumentId,
      between: command.between,
      target: command.target,
    });
    return commit(this.store, this.rebuild, document);
  }
}
