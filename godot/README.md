# TopoRoom Godot roam (read-only)

Godot **4.3+** host for checking exported floor-plan solids. It instances a
`.glb` derived from SceneIR. It must **not** write dimensions or SceneIR
(I7, I8).

## Open

1. Install [Godot 4.3+](https://godotengine.org/).
2. Import / open `godot/project.godot`.
3. Main scene `roam.tscn` instances
   `godot/fixtures/rect-room-door-laser.glb` (Storey_ / Wall_ / Room_ /
   Opening_ nodes).
4. Press Play. Orbit with the editor camera or the scene Camera3D.

## Regenerate the fixture glb

From the repo root (after a normal CMake build):

```bash
cmake --build build --target toporoom_write_godot_fixture
./build/core/toporoom_write_godot_fixture godot/fixtures/rect-room-door-laser.glb
```

The exporter converts millimetres to metres once (`kMmToM`) and requires a
successful GeometryPort rebuild (StatusGate). A Fault does not emit `.glb`.
