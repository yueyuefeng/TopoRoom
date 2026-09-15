export type DomainEvent =
  | WallAdded
  | OpeningAdded
  | RoomClosed
  | StoreyHeightChanged
  | FloorPlanSemanticsChanged;

export interface WallAdded {
  type: "WallAdded";
  documentId: string;
  storeyId: string;
  wallId: string;
}

export interface OpeningAdded {
  type: "OpeningAdded";
  documentId: string;
  storeyId: string;
  wallId: string;
  openingId: string;
}

export interface RoomClosed {
  type: "RoomClosed";
  documentId: string;
  storeyId: string;
  roomId: string;
  wallIds: readonly string[];
}

export interface StoreyHeightChanged {
  type: "StoreyHeightChanged";
  documentId: string;
  storeyId: string;
  heightMm: number;
}

export interface FloorPlanSemanticsChanged {
  type: "FloorPlanSemanticsChanged";
  documentId: string;
  revision: number;
}
