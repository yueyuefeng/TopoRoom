import type { SceneIR } from "@toporoom/domain-floorplan";
import type { FloorPlanSolidSemantics } from "./geometry-port.js";

export function semanticsFromSceneIR(scene: SceneIR): FloorPlanSolidSemantics {
  return {
    documentId: scene.id,
    revision: scene.revision,
    storeys: scene.storeys.map((storey) => ({
      id: storey.id,
      heightMm: storey.heightMm,
      elevationMm: storey.elevationMm,
      walls: storey.walls.map((wall) => ({
        id: wall.id,
        start: wall.start,
        end: wall.end,
        thicknessMm: wall.thicknessMm,
        heightMm: wall.heightMm,
        openings: wall.openings.map((opening) => ({
          id: opening.id,
          widthMm: opening.widthMm,
          heightMm: opening.heightMm,
          offsetMm: opening.offsetMm,
          sillHeightMm: opening.sillHeightMm,
        })),
      })),
      rooms: storey.rooms.map((room) => ({
        id: room.id,
        wallIds: room.wallIds,
      })),
    })),
  };
}
