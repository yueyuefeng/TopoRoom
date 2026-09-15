export const WALL_KINDS = ["exterior", "interior", "partition"] as const;
export type WallKind = (typeof WALL_KINDS)[number];

export const OPENING_KINDS = ["door", "window"] as const;
export type OpeningKind = (typeof OPENING_KINDS)[number];
