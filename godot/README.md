# Godot 4 host (InteractionShell + Visualization)

Godot **4.3+** is the P0 phone/desktop **host**: menus, 引导量房, 2D 户型图,
command-synced **3D 编辑**, and read-only `.glb` roam. The editable truth
remains C++ SceneIR / `FloorPlanDocument`. Lighting is Visualization-only.
See [ADR-001](../docs/architecture/ADR-001-godot-interaction-shell-host.md)
and [ADR-002](../docs/architecture/ADR-002-godot-3d-command-synced-edit.md).

```
Godot UI (GDScript)
    → GDExtension TopoRoomHost
        → C API (toporoom.h)
            → toporoom_core (FloorPlanDocument)
```

The previous Kotlin JNI app in `mobile/android/` is a **legacy / test stub**.
Do not delete it; it still exercises JNI + Fake capture. New Android APKs
should come from this Godot project + export templates.

## Open in the editor

1. Build the desktop extension (Linux example):

   ```bash
   ./godot/scripts/build_extension.sh
   ```

   This FetchContents [godot-cpp 4.3](https://github.com/godotengine/godot-cpp)
   and writes `godot/bin/libtoporoom.linux.template_debug.x86_64.so`.

2. Install [Godot 4.3+](https://godotengine.org/) (standard or .NET not required).
   Linux CJK: `fonts-noto-cjk` so labels render.

3. Import / open `godot/project.godot` (this directory).

4. Play. Home is a phone-style list: **拍户型图** (system camera),
   **从相册导入** (system gallery / Photo Picker), **引导量房**, plus a
   current-plan card. **拍户型图** requests CAMERA, launches
   `ACTION_IMAGE_CAPTURE`, copies the JPEG to `user://imports/`, previews it,
   then runs `FakeVisionAdapter`. Desktop falls back to a file dialog.
   After walls appear you can tap to set 承重 vs 隔墙, then 拆改
   (shear walls need confirm). The 2D canvas draws SceneIR JSON, not a mesh.

UI 预览（首页 / 引导 / 拍户型图 / 预览 / 拆改 / 3D）：
[docs/screenshots/README.md](../docs/screenshots/README.md).

Without the `.so`, the editor still opens; the UI shows `GDExtension 未加载`.

## GDExtension layout

```
godot/
  project.godot
  toporoom.gdextension          entry_symbol = toporoom_library_init
  app/                          GDScript + scenes
  extension/                    CMake + C++ (godot-cpp + toporoom_core)
  bin/                          built .so (gitignored)
  fixtures/                     SceneIR JSON + sample .glb
  scripts/build_extension.sh
  scripts/export_android_debug.sh
  export_presets.cfg
```

Standalone CMake (same as the script):

```bash
cmake -S godot/extension -B build-gdext -DCMAKE_BUILD_TYPE=Debug
cmake --build build-gdext --parallel --target toporoom_gdextension
```

From the repo root: `-DTOPOROOM_BUILD_GDEXTENSION=ON`.

### Android `arm64-v8a` (+ optional `x86_64` emulator)

Needs Android NDK r25+ (C++20) and network on first configure (manifold +
godot-cpp).

```bash
export ANDROID_NDK=/path/to/ndk
./godot/scripts/build_extension.sh android arm64-v8a
./godot/scripts/build_extension.sh android x86_64   # emulator
```

Outputs:

| ABI | Godot library key | File |
|-----|-------------------|------|
| arm64-v8a | `android.*.arm64` | `bin/libtoporoom.android.template_debug.arm64.so` |
| x86_64 | `android.*.x86_64` | `bin/libtoporoom.android.template_debug.x86_64.so` |

Release builds (`BUILD_TYPE=Release`) use `template_release` in the filename.
`toporoom.gdextension` lists both debug and release.

Manifold and `toporoom_core` are **statically** linked into that one `.so`.
No extra JNI `.so` is required at export time.

## Export a Debug APK

CI / this Cloud VM typically **cannot** finish an APK: Godot export templates
and a local Android SDK/NDK/JDK are missing. Deliverable here is the project
+ scripts; run the last mile on a machine with the editor.

1. Godot 4.3+ **Editor Settings → Export → Android**
   - JDK 17
   - Android SDK (API 34)
   - NDK (side-by-side; same one used to compile the `.so`)
   - Debug keystore (editor can generate)
2. **Install Android Build Template** (Editor → Manage Export Templates)
   matching the Godot version (4.3.x).
3. Build the Android `.so` files above into `godot/bin/`.
4. Open `godot/`, confirm the Android preset in `export_presets.cfg`
   (`com.toporoom.godot`, arm64-v8a phone APK, Gradle build, CAMERA /
   READ_MEDIA_IMAGES). Enable x86_64 only after building the emulator `.so`.
   Rebuild `TopoRoomMedia` AARs: `./godot/scripts/build_android_plugin.sh`.
5. **Project → Export → Android → Export Debug APK**, or:

   ```bash
   GODOT=/path/to/Godot_v4.3-stable_linux.x86_64 \
     ./godot/scripts/export_android_debug.sh
   ```

`export_credentials.cfg` is local (keystore passwords) — do not commit it.

## 3D 编辑 + light presets

**3D 编辑** (next to **漫游检查**) builds `MeshInstance3D` walls / 门洞 / 窗洞 /
垭口 / floor from SceneIR (mm → metres: `X=x/1000`, `Y=height/1000`,
`Z=y/1000`). Yellow spheres are gizmos:

| Handle | Command |
|--------|---------|
| Wall endpoint | `Session.move_shared_vertex` → `move_wall` |
| Opening centre / edges | `Session.update_opening_geom` → `update_opening` |
| Wall top / storey corner | `set_wall_height` / `set_storey_height` |

On pointer-up the host **auto_saves** SceneIR and probes StatusGate. A
rebuild **Fault** keeps the previous solid preview and shows the error;
dragged triangles are not kept as mm.

**白天 / 暖光** is a segmented control on the 3D HUD (`godot/app/lighting.gd`):
`WorldEnvironment`, `DirectionalLight3D` with shadows, Omni fill, and (暖光) a
spot. Materials are `StandardMaterial3D` roughness/metallic for
**gl_compatibility** (mobile). Lighting never writes dimensions. 承重墙 uses a
warmer plaster than 砌体/隔墙.

Load a room first (画矩形四墙, Fake 一室, or **加载夹具样例** inside 3D 编辑).

Invariant check (no Godot binary required):

```bash
./godot/scripts/check_3d_edit_invariants.sh
```

`.glb` **漫游检查** is still read-only.

## What Godot is allowed to do

| Allowed | Not allowed |
|---------|-------------|
| Buttons / FSM UI calling C API commands | Treating dragged vertices as mm truth |
| 2D nodes drawn **from** SceneIR walls | Treating Godot Node as FloorPlanDocument |
| 3D gizmos that **commit commands** (ADR-002) | Free-form sculpt that bypasses SceneIR |
| `GLTFDocument` load of exported `.glb` | Writing `extras` / roam node transforms back to SceneIR |
| Lights / shadows / materials (Visualization) | Lighting writing dimensions |
| Save/load `.sceneir.json` via C API | Second truth source in `user://` besides SceneIR |

DXF / PDF / glb still come from C++ `StatusGate`. Fault rejects structural
`.glb` and still allows semantic DXF/PDF.

## Regenerate the fixture glb

```bash
cmake --build build --target toporoom_write_godot_fixture
./build/core/toporoom_write_godot_fixture godot/fixtures/rect-room-door-laser.glb
```
