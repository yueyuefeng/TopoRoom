# Android host (skeleton)

Native Android UI is **not** in this milestone. This package is the NDK/JNI
bridge that will load `toporoom_core` into an Android app.

```
mobile/android/
  CMakeLists.txt                 # NDK shared library
  src/main/cpp/toporoom_jni.cpp  # JNI → C API
  src/main/java/.../NativeCore.java
```

Gradle (later) should point `externalNativeBuild.cmake.path` at this
`CMakeLists.txt` and pass `-DTOPOROOM_BUILD_TESTS=OFF`.

Whitelist / USB Host / BT **permission flags** live in
`core/fixtures/android-whitelist.v1.json` (versioned C++-loaded table).
This JNI skeleton does not prompt; the real app module must request
`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and USB host/device permission.
**iOS external depth is out of P0.**
