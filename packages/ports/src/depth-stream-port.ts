export type DepthPrinciple = "structured_light" | "active_stereo" | "unknown";

export interface AccessoryProfile {
  deviceId: string;
  name: string;
  vid?: string;
  pid?: string;
  sku?: string;
  principle: DepthPrinciple;
  powerHint?: string;
  firmwareVersion?: string;
}

export interface StreamHandle {
  deviceId: string;
}

export interface DepthStreamOptions {
  fps?: number;
}

export interface DepthFrameDTO {
  width: number;
  height: number;
  timestamp: number;
  depthsMm: Float32Array;
}

export interface ColorFrameDTO {
  width: number;
  height: number;
  timestamp: number;
  rgba: Uint8Array;
}

export interface CameraIntrinsics {
  fx: number;
  fy: number;
  cx: number;
  cy: number;
}

export interface Extrinsics {
  rotation: readonly number[];
  translationMm: readonly number[];
}

export interface DepthStreamPort {
  discover(): Promise<readonly AccessoryProfile[]>;
  open(deviceId: string, options?: DepthStreamOptions): Promise<StreamHandle>;
  readFrame(
    timeoutMs: number,
  ): Promise<DepthFrameDTO | { depth: DepthFrameDTO; color?: ColorFrameDTO }>;
  getIntrinsics(): Promise<CameraIntrinsics>;
  getExtrinsicsToImu(): Promise<Extrinsics | undefined>;
  getFirmwareVersion(): Promise<string>;
  close(): Promise<void>;
}
