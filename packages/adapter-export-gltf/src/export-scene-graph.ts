import type { SceneIR } from "@toporoom/domain-floorplan";
import type { MeshProjection } from "@toporoom/ports";

export const COMPILER_GENERATOR = "toporoom-compiler/0.1.0";
export const MM_TO_M = 0.001;

export interface SceneGraphExtras {
  toporoomId: string;
  kind: "storey" | "wall" | "room" | "opening";
}

export interface SceneGraphNode {
  name: string;
  extras: SceneGraphExtras;
  translationMeters?: [number, number, number];
  children: string[];
}

export interface SceneGraph {
  generator: string;
  sourceUnits: "mm";
  units: "m";
  nodes: SceneGraphNode[];
}

export interface GltfJson {
  asset: { version: "2.0"; generator: string };
  scene: number;
  scenes: { nodes: number[] }[];
  nodes: {
    name: string;
    extras: SceneGraphExtras;
    children?: number[];
    mesh?: number;
    translation?: [number, number, number];
  }[];
  meshes?: {
    primitives: { attributes: { POSITION: number }; indices?: number }[];
  }[];
  accessors?: {
    bufferView: number;
    componentType: number;
    count: number;
    type: "VEC3" | "SCALAR";
    max?: number[];
    min?: number[];
  }[];
  bufferViews?: { buffer: number; byteOffset: number; byteLength: number }[];
  buffers?: { byteLength: number; uri: string }[];
}

export function exportSceneGraph(
  scene: SceneIR,
  meshes: MeshProjection,
): SceneGraph {
  const nodes: SceneGraphNode[] = [];
  for (const storey of scene.storeys) {
    const storeyName = `Storey_${storey.id}`;
    const children: string[] = [];
    for (const wall of storey.walls) {
      const wallName = `Wall_${wall.id}`;
      children.push(wallName);
      nodes.push({
        name: wallName,
        extras: { toporoomId: wall.id, kind: "wall" },
        children: wall.openings.map((opening) => `Opening_${opening.id}`),
        translationMeters: midpointMeters(wall.start, wall.end),
      });
      for (const opening of wall.openings) {
        nodes.push({
          name: `Opening_${opening.id}`,
          extras: { toporoomId: opening.id, kind: "opening" },
          children: [],
        });
      }
    }
    for (const room of storey.rooms) {
      const roomName = `Room_${room.id}`;
      children.push(roomName);
      nodes.push({
        name: roomName,
        extras: { toporoomId: room.id, kind: "room" },
        children: [],
      });
    }
    nodes.unshift({
      name: storeyName,
      extras: { toporoomId: storey.id, kind: "storey" },
      translationMeters: [0, storey.elevationMm * MM_TO_M, 0],
      children,
    });
  }
  void meshes;
  return {
    generator: COMPILER_GENERATOR,
    sourceUnits: "mm",
    units: "m",
    nodes,
  };
}

export function exportGltfJson(
  scene: SceneIR,
  meshes: MeshProjection,
): GltfJson {
  const graph = exportSceneGraph(scene, meshes);
  const indexByName = new Map(graph.nodes.map((node, index) => [node.name, index]));
  const nodes = graph.nodes.map((node) => {
    const gltfNode: GltfJson["nodes"][number] = {
      name: node.name,
      extras: node.extras,
    };
    if (node.children.length > 0) {
      gltfNode.children = node.children.map((child) => {
        const index = indexByName.get(child);
        if (index === undefined) {
          throw new Error(`Missing child node ${child}`);
        }
        return index;
      });
    }
    if (node.translationMeters) {
      gltfNode.translation = node.translationMeters;
    }
    const solid = meshes.solids.find(
      (candidate) => candidate.nodeHint === node.name && candidate.verticesMm.length > 0,
    );
    if (solid) {
      gltfNode.mesh = 0;
    }
    return gltfNode;
  });

  const positions: number[] = [];
  for (const solid of meshes.solids) {
    for (const value of solid.verticesMm) {
      positions.push(value * MM_TO_M);
    }
  }
  const bytes = float32Buffer(positions);
  const max = [-Infinity, -Infinity, -Infinity];
  const min = [Infinity, Infinity, Infinity];
  for (let i = 0; i < positions.length; i += 3) {
    max[0] = Math.max(max[0]!, positions[i]!);
    max[1] = Math.max(max[1]!, positions[i + 1]!);
    max[2] = Math.max(max[2]!, positions[i + 2]!);
    min[0] = Math.min(min[0]!, positions[i]!);
    min[1] = Math.min(min[1]!, positions[i + 1]!);
    min[2] = Math.min(min[2]!, positions[i + 2]!);
  }
  const vertexCount = positions.length / 3;

  const rootNodes = graph.nodes
    .map((node, index) => ({ node, index }))
    .filter(({ node }) => node.extras.kind === "storey")
    .map(({ index }) => index);

  return {
    asset: { version: "2.0", generator: COMPILER_GENERATOR },
    scene: 0,
    scenes: [{ nodes: rootNodes }],
    nodes,
    ...(vertexCount > 0
      ? {
          meshes: [
            {
              primitives: [{ attributes: { POSITION: 0 } }],
            },
          ],
          accessors: [
            {
              bufferView: 0,
              componentType: 5126,
              count: vertexCount,
              type: "VEC3",
              max,
              min,
            },
          ],
          bufferViews: [
            { buffer: 0, byteOffset: 0, byteLength: bytes.byteLength },
          ],
          buffers: [
            {
              byteLength: bytes.byteLength,
              uri: `data:application/octet-stream;base64,${bytesToBase64(bytes)}`,
            },
          ],
        }
      : {}),
  };
}

function midpointMeters(
  start: { x: number; y: number },
  end: { x: number; y: number },
): [number, number, number] {
  return [
    ((start.x + end.x) / 2) * MM_TO_M,
    0,
    ((start.y + end.y) / 2) * MM_TO_M,
  ];
}

function float32Buffer(values: number[]): Uint8Array {
  const buffer = new ArrayBuffer(values.length * 4);
  new Float32Array(buffer).set(values);
  return new Uint8Array(buffer);
}

function bytesToBase64(bytes: Uint8Array): string {
  return Buffer.from(bytes).toString("base64");
}
