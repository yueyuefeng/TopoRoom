import type { GeometryFault } from "./geometry-port.js";

export interface NotifyPort {
  info(message: string, context?: Record<string, unknown>): void;
  warn(message: string, context?: Record<string, unknown>): void;
  error(message: string, context?: Record<string, unknown>): void;
  geometryFault(fault: GeometryFault): void;
}
