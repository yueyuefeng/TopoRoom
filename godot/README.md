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

4. Play. Home is a branded workbench: **新建方案** / **拍户型图**（占位） /
   **引导量房**, a paper 户型图 card, and chips for Fake 一室 / 导出 / 3D 编辑 /
   漫游. The 2D canvas draws 承重/砌体 walls and 门窗洞/垭口 from SceneIR JSON,
   not from a triangle mesh. Visual tokens live in `app/theme/`.

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

**Sideload (arm64 phone):** Android **7.0+ (API 24)**, **arm64-v8a** only.
Package `com.toporoom.godot`, debug-signed (`androiddebugkey`). Not for Play Store.

```bash
adb install -r build/toporoom-android-debug.apk
```

On device: allow install from this source if prompted. Bluetooth permission is
declared for later laser capture; the P0 UI runs without hardware.

### One-command local recipe (Linux)

Needs Godot **4.3.stable** editor binary, matching **export templates**
(`android_debug.apk` + `android_source.zip` under
`~/.local/share/godot/export_templates/4.3.stable/`), **OpenJDK 17**, and
Android SDK (`platforms;android-34`, `build-tools;34.0.0`,
`ndk;23.2.8568313` as Godot 4.3 documents):

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_NDK=$ANDROID_HOME/ndk/23.2.8568313
export GODOT=/path/to/Godot_v4.3-stable_linux.x86_64

./godot/scripts/build_extension.sh android arm64-v8a
# optional emulator ABI:
# ./godot/scripts/build_extension.sh android x86_64

GODOT=$GODOT \
  GODOT_ANDROID_KEYSTORE_DEBUG_PATH=$ANDROID_HOME/debug.keystore \
  ./godot/scripts/export_android_debug.sh build/toporoom-android-debug.apk
```

`export_android_debug.sh` runs `--install-android-build-template` with
`--export-debug`. Editor Settings must have Java SDK + Android SDK paths
(or generate `~/.config/godot/editor_settings-4.3.tres` once). Debug
keystore: `keytool -genkeypair` alias `androiddebugkey` / password `android`.

Preset `export_presets.cfg`: `com.toporoom.godot`, **arm64-v8a**, Gradle,
minSdk 24 / target 34. Enable `architectures/x86_64` only after building
that `.so`. `export_credentials.cfg` is local — do not commit it.

Android `.so` is linked with `c++_static` so the APK does not depend on a
separate app copy of `libc++_shared` for TopoRoomHost (Godot’s own
`libgodot_android.so` still ships `libc++_shared.so`).

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
