export interface LaserDeviceProfile {
  deviceId: string;
  name: string;
  sku?: string;
  principle: "laser";
}

export interface LaserHandle {
  deviceId: string;
}

export interface MeasureSample {
  valueMm: number;
  timestamp: number;
  source: "laser" | "typed";
  instrumentId: string;
  rawRssi?: number;
}

export interface LaserRangefinderPort {
  discover(): Promise<readonly LaserDeviceProfile[]>;
  connect(deviceId: string): Promise<LaserHandle>;
  readLengthMm(): Promise<MeasureSample>;
  disconnect(): Promise<void>;
}
