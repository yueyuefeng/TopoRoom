#!/usr/bin/env bash
exec "$(cd "$(dirname "$0")/.." && pwd)/godot/scripts/bump_android_version.sh" "$@"
