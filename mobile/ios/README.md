# iOS host (skeleton)

Godot is **not** the iOS app. TopoRoom on iOS will be a native Swift UI that
links the same C++ core via Objective-C++.

```
mobile/ios/TopoRoomCore/
  TopoRoomCore.h     # umbrella / bridging header
  TopoRoomCore.mm    # ObjC++ → C API
  TopoRoomCore.swift # Swift wrapper
```

Xcode (later): add `core/` as a CMake-built static library (or compile the
`core/src` files into the app target), set `TopoRoomCore.h` as the Swift
bridging header, and never write SceneIR from Godot.
