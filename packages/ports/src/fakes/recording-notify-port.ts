import type { GeometryFault } from "../geometry-port.js";
import type { NotifyPort } from "../notify-port.js";

export interface NotifyRecord {
  level: "info" | "warn" | "error" | "geometryFault";
  message?: string;
  context?: Record<string, unknown>;
  fault?: GeometryFault;
}

export class RecordingNotifyPort implements NotifyPort {
  readonly records: NotifyRecord[] = [];

  info(message: string, context?: Record<string, unknown>): void {
    this.records.push({ level: "info", message, context });
  }

  warn(message: string, context?: Record<string, unknown>): void {
    this.records.push({ level: "warn", message, context });
  }

  error(message: string, context?: Record<string, unknown>): void {
    this.records.push({ level: "error", message, context });
  }

  geometryFault(fault: GeometryFault): void {
    this.records.push({ level: "geometryFault", fault });
  }
}
