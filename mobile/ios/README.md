# iOS host (software core)

Native SwiftUI app that links the same C++ core through Objective-C++
(`TRCore` → `toporoom.h`). **P0: depth capture Android-first** — there is no
USB / Type-C depth path on iOS. Typed measurements and the Fake one-room loop
are enough to open/edit a FloorPlan and export glb/DXF/PDF.

This cloud environment has **no Mac / Xcode / simulator**. Sources and the
shared scheme are complete; build locally on a Mac.

## Open in Xcode

1. Build `toporoom_core` so `libtoporoom_core.a` exists (see Linking below).
2. Open `mobile/ios/TopoRoom.xcodeproj`.
3. Scheme **TopoRoom** (shared: `xcshareddata/xcschemes/TopoRoom.xcscheme`).
4. Run on a simulator or device (iOS 16+).

Bridging header: `TopoRoom/TopoRoom-Bridging-Header.h` → `TopoRoomCore.h`.

## Linking `libtoporoom_core.a`

The app target does **not** compile Manifold itself. It links the CMake static
library:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DTOPOROOM_BUILD_TESTS=OFF -DCMAKE_CXX_COMPILER=c++
cmake --build build --parallel --target toporoom_core
```

Xcode `LIBRARY_SEARCH_PATHS` includes `../../build/core` and `../../build`.
`OTHER_LDFLAGS` = `-ltoporoom_core -lc++`.
`HEADER_SEARCH_PATHS` = `../../core/include` and `TopoRoomCore`.

For a true iOS slice of the archive, configure CMake with an iOS toolchain
(or add the `core/src` + FetchContent deps as an Xcode CMake External target)
and point `LIBRARY_SEARCH_PATHS` at that output. Simulator vs device slices
must match the run destination.

## Fake / typed capture loop

The UI copy states **P0: depth capture Android-first**.

**Run Fake one-room loop** calls `toporoom_debug_fake_one_room` (same C API as
Android): rectangle walls, two laser-source key edges from the Fake adapter
path (no radio), one door, export to `Documents/export/`.

Alternatively: Draw walls → typed explicit millimetres → door → Close room +
export. Guide completion still requires `≥2` typed keys with the explicit
flag (set automatically for `source=typed` on this host).

## Layout

```
mobile/ios/
  TopoRoom.xcodeproj/           shared scheme TopoRoom
  TopoRoom/                     SwiftUI shell
  TopoRoomCore/                 ObjC++ / Swift wrapper
```
