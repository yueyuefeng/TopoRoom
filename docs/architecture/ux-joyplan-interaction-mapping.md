# JoyPlan-style interaction mapping (Godot host)

- **Status**: Implemented on the Godot InteractionShell (P0)
- **Depends**: [ADR-001](./ADR-001-godot-interaction-shell-host.md),
  [ADR-002](./ADR-002-godot-3d-command-synced-edit.md),
  [ADR-003](./ADR-003-floorplan-vision-no-ocr-p0.md),
  closed outer envelope (`seal_outer_envelope` / gold-sample gtests)

This maps the JoyPlan-like sequence **calibrate → closed walls → drag
door/window → FAB 2D↔3D** onto TopoRoom. Godot never owns millimetres:
every structural write goes `Control/gizmo → Session → TopoRoomHost → C API
→ FloorPlanDocument / SceneIR`.

The full gesture table, state machine, gap matrix, and Phase B–E commit
plan live in [joyplan-interaction-spec.md](./joyplan-interaction-spec.md).

## Sequence

| Step | JoyPlan-style UX | TopoRoom host | Command / truth |
|------|------------------|---------------|-----------------|
| 1 | Pick camera / gallery photo | `photo_stub.gd` + `media_picker.gd` | Image stored under `user://imports/`; not SceneIR |
| 2 | Two-handle scale + mm (+ loupe) | `scale_calibrate.gd` | `Session.import_photo_vision(uri, mm_per_px)` → `toporoom_vision_import_image_ex` / `RasterAnalyzeOptions.mm_per_px_override` |
| 3 | Closed outer envelope (walls) | Raster analyzer + `seal_outer_envelope` | `add_wall` / `add_opening` from vision; thin grey 阳台/落地窗 are masonry host + opening, not air |
| 4 | Room fill + name / area on 2D | `plan_canvas.gd` `_draw_room_fills` | **View only.** Flood pockets of closed walls; labels from SceneIR `rooms` when present |
| 5 | Bottom-sheet door/window library, long-press drag, snap | `opening_library.gd` + `plan_canvas.snap_opening` | `Session.add_opening(kind, wall_id, offset_mm)` |
| 6 | Select entity → contextual toolbar + top L/W/H | 2D: `photo_stub.gd` readout + `_ctx`; 3D: `edit_3d.gd` `_lwh` / `_ctx` | Kind changes: `set_wall_kind`. Dims are readout of SceneIR (3D drag still commits via gizmos, ADR-002) |
| 7 | FAB 2D ↔ 3D | Round FAB on review sheet and 3D HUD | Scene switch only. 3D edit gizmos / lighting / StatusGate preview unchanged (ADR-002) |

Optional polish (same host, still Visualization-only):

- **Load-bearing hatch** — denser diagonal ticks on shear/exterior strokes in `plan_canvas.gd`.
- **3D dimension overlay** — `尺寸` chip in `edit_3d.gd` unprojects wall lengths; does not write SceneIR.

Out of scope (not mapped): Elevation Index CAD dark mode; electric/furniture library.

## Files

| File | Role |
|------|------|
| `godot/app/scale_calibrate.gd` | Handles A/B, loupe, mm sheet |
| `godot/app/plan_canvas.gd` | SceneIR 2D view: fills, hatch, snap, drop preview |
| `godot/app/opening_library.gd` | Bottom-sheet chips; long-press drag ghost |
| `godot/app/photo_stub.gd` | Import → calibrate → review/demolish sheet + FAB |
| `godot/app/edit_3d.gd` | Command-synced 3D; L/W/H; FAB back to 2D; dim overlay |
| `godot/app/session.gd` | InteractionShell façade |
| `godot/extension/src/toporoom_host.cpp` | `import_vision_image(path, mm_per_px)` |

## Invariants

1. Photo pixels and Godot meshes are not mm truth (I1 / I8).
2. Calibration override scales the raster downsample factor; skipping calibration keeps analyzer wall-thickness estimate.
3. Room name/area labels are best-effort from closed pockets, not OCR.
4. Opening drop must snap to a wall segment; otherwise the library refuses the drop.
5. FAB does not bypass StatusGate: 3D solids still refresh from SceneIR / last good preview.
