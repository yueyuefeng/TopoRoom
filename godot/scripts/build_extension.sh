#!/usr/bin/env bash
# Build the TopoRoom GDExtension shared library into godot/bin/.
#
# Linux editor / CI:
#   ./godot/scripts/build_extension.sh
#
# Android (requires ANDROID_NDK or ANDROID_NDK_HOME):
#   ./godot/scripts/build_extension.sh android arm64-v8a
#   ./godot/scripts/build_extension.sh android x86_64
#
# Optional: BUILD_TYPE=Release ./godot/scripts/build_extension.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLATFORM="${1:-linux}"
ABI="${2:-}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
SRC="$ROOT/godot/extension"

if [[ "$PLATFORM" == "android" ]]; then
  NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}}"
  if [[ -z "$NDK" && -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/ndk" ]]; then
    NDK="$(ls -d "$ANDROID_HOME/ndk"/* 2>/dev/null | tail -n 1 || true)"
  fi
  if [[ -z "$NDK" || ! -f "$NDK/build/cmake/android.toolchain.cmake" ]]; then
    echo "ANDROID_NDK / ANDROID_NDK_HOME is not set or missing cmake toolchain." >&2
    echo "Install the Android NDK and export ANDROID_NDK." >&2
    exit 1
  fi
  ABI="${ABI:-arm64-v8a}"
  BUILD_DIR="$ROOT/build-gdext-android-$ABI"
  cmake -S "$SRC" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$ABI" \
    -DANDROID_PLATFORM=android-24 \
    -DANDROID_STL=c++_shared
else
  BUILD_DIR="$ROOT/build-gdext"
  cmake -S "$SRC" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_CXX_COMPILER="${CXX:-g++}"
fi

JOBS="${CMAKE_BUILD_PARALLEL_LEVEL:-2}"
cmake --build "$BUILD_DIR" --parallel "$JOBS" --target toporoom_gdextension
echo "Libraries in $ROOT/godot/bin:"
ls -l "$ROOT/godot/bin"/libtoporoom.* 2>/dev/null || ls -l "$ROOT/godot/bin"
