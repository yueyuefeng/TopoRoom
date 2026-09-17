# ADR-001 — Godot as InteractionShell host (APK via export templates)

- **Status**: Accepted (product decision 2026-09-17)
- **Base**: FINAL architecture (2026-09-15) remains the domain/geometry spec

## Decision

Ship the P0 **phone host** as a **Godot 4.x** project. Build the APK with
Godot's Android export templates, not as a first-party Kotlin/Gradle UI.

C++ `FloorPlanDocument` / SceneIR stays the **only editable truth**. Godot is
the **InteractionShell + Visualization** process:

```
Godot UI (guided flow, 2D 户型图, HUD)
    → GDExtension (TopoRoomHost)
        → C API / app services
            → Domain (SceneIR)
Deliverables StatusGate → .glb / DXF / PDF
Godot roam ← load .glb read-only
Godot 3D 编辑 ← SceneIR meshes + gizmos → C API commands (ADR-002)
```

## Why

- One UI stack for desktop editor, Android, and (later) iOS export.
- Existing roam/glb pipeline already assumes Godot 4.
- Kotlin JNI remains useful for JNI/Fake tests but is no longer the P0 APK path.

## What this is not

Godot is **not** a free-form mesh CAD that writes millimetres back from
triangles, node transforms, or glTF `extras`. That would violate I1 and I8
and the FINAL rule "Godot 可当编辑器 = 不进 MVP".

| Layer | Role |
|-------|------|
| SceneIR / FloorPlanDocument | Sole editable 方案 |
| Godot Control / Node2D 户型图 | View of SceneIR; clicks issue **commands** |
| Godot Node3D 3D 编辑 | Interactive meshes/gizmos; commit → C API → SceneIR (ADR-002) |
| Godot Node3D roam | VisualizationDerivative / Deliverables consumer; **glb only** |
| Kotlin `mobile/android/` | Legacy JNI stub; keep for tests, do not delete abruptly |

## Relation to FINAL I7

FINAL I7 said "Godot = glTF Conformist 只读宿主". That still holds for
**mesh**: exported `.glb` is a Published Language; roam must not write
dimensions. The 2026-09-17 host pivot adds: Godot may also **present** the
InteractionShell UI, provided every edit is a command through the C API.

I8 (VisualizationDerivative must not write dimensions back) is unchanged.

## Amendment (2026-09-17) — 3D gizmos

Product follow-up: the 3D viewport **may** present interactive wall/opening
meshes. That does **not** revive “Godot as mesh CAD”. See
[ADR-002](./ADR-002-godot-3d-command-synced-edit.md): gizmo commit → C API →
SceneIR; rebuild from Domain; lighting is Visualization-only; `.glb` roam
stays read-only.

The I7 sentence “Godot = glTF Conformist 只读宿主” continues to apply to
**Deliverables `.glb`**, not to the command-synced edit scene.

## Consequences

- P0 Android APK = `godot/` + `libtoporoom.*.so` + Godot export templates.
- Cloud CI builds the Linux `.so` when feasible; full APK export needs local
  Godot templates + SDK/NDK/JDK.
- Domain, GeometryPort, StatusGate, and exporters stay in `core/`.
