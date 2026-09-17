# ADR-002 — Command-synced 3D edit in the Godot viewport

- **Status**: Accepted (product decision 2026-09-17)
- **Amends**: [ADR-001](./ADR-001-godot-interaction-shell-host.md)
- **Base**: FINAL architecture (2026-09-15) remains the domain/geometry spec

## Decision

Pivot from “Godot UI only / mesh never editable” to:

- The Godot **3D viewport may edit** walls, openings (门洞/窗洞/垭口), and
  hosted components as **interactive meshes and gizmos**.
- Every structural edit **must sync back**:

```
Godot gizmo commit
    → GDExtension TopoRoomHost
        → C API command (move_wall / update_opening / set_wall_height / …)
            → FloorPlanDocument / SceneIR  (sole millimetre truth)
                → Domain rebuild
                    → refresh Godot meshes from rebuilt SceneIR / solids
```

Dragged triangle vertices, node transforms, and glTF `extras` are **never**
permanent mm truth without a command (I1, I8).

**Lighting / shadows / materials / WorldEnvironment** are Visualization
layer: allowed freely; they must not write dimensions.

`.glb` **漫游检查** stays a read-only Deliverables consumer (I7 mesh).

## Sync rules

1. **Live drag preview** (pointer move) mutates a **local copy** of SceneIR and
   rebuilds lightweight `BoxMesh` extrusions every motion so walls follow the
   finger. This preview is not millimetre truth and does not call C API.
2. **Gizmo commit** (pointer up) issues an existing C API command through
   `Session` → `TopoRoomHost`. The 3D scene does not call Domain itself and
   does not call `add_wall` / `set_measurement` except via that host façade.
3. After a successful command, InteractionShell **`auto_save`s SceneIR**
   JSON under `user://schemes/`.
4. After edit, probe `rebuild_status` (StatusGate):
   - **OK** — discard the previous solid preview; rebuild `MeshInstance3D`
     from the current SceneIR.
   - **Fault** — **keep the previous solid preview** and show the StatusGate
     message in the HUD. Do not silently accept the dragged mesh as truth.
     SceneIR still holds the command result (Domain is source of truth).
5. 2D 户型图 remains a SceneIR view. Button **3D 编辑** (next to **漫游**)
   opens the edit viewport.

## Lighting package

`godot/app/lighting.gd` (used by 3D 编辑 and 漫游):

| Node | Role |
|------|------|
| `WorldEnvironment` | Solid background + ambient (gl_compatibility) |
| `DirectionalLight3D` | Key light, **`shadow_enabled`** |
| `OmniLight3D` / `SpotLight3D` | Interior fill / 暖光 mood |

Presets **白天** / **暖光** are HUD toggles. Materials are
`StandardMaterial3D` with roughness/metallic suitable for
`renderer/rendering_method=gl_compatibility` (mobile APK). Lighting must not
call C API edit commands.

## What this is not

- Free-form sculpt or CSG that bypasses `FloorPlanDocument`
- Treating `MeshInstance3D` vertex positions as millimetres
- Writing roam `.glb` nodes back into SceneIR

## Relation to FINAL I7 / I8

I7 still holds for **exported mesh**: `.glb` is Published Language; roam
must not write dimensions. ADR-001’s “Godot Node3D roam = visualization
only” is unchanged. This ADR adds: a **separate** 3D edit scene may issue
the same commands the 2D UI already issues.

I8 (VisualizationDerivative must not write dimensions) is unchanged:
lights, shadows, and materials are VisualizationDerivative.

## Consequences

- `godot/app/edit_3d.tscn` generates wall/opening/room meshes from SceneIR.
- Handles: wall endpoints, opening offset/width, storey/wall height.
  Distinct colors plus hover/press highlight; tap shows a short Chinese tip
  (e.g. 「墙端点：拖动改墙线」). A HUD legend and first-time coach mark
  explain that the spheres are draggable.
- During drag, BoxMesh walls/openings (and on-canvas mm) update every motion
  from a duplicated SceneIR snapshot. StatusGate / `auto_save` still run only
  on pointer-up.
- Selected 门洞/窗洞/垭口 get emissive feedback.
- Android export notes in `godot/README.md` are unchanged (templates + NDK).
