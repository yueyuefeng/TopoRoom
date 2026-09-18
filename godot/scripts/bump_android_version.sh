#!/usr/bin/env bash
# Bump Android versionCode (+1) and versionName before every APK export.
#
#   ./godot/scripts/bump_android_version.sh           # 0.1.0 → 0.1.1
#   ./godot/scripts/bump_android_version.sh minor     # 0.1.1 → 0.2.0
#   ./godot/scripts/bump_android_version.sh major     # 0.2.0 → 1.0.0
#   ./godot/scripts/bump_android_version.sh build     # 0.1.0 → 0.1.0+1
#   VERSION_NAME=0.1.0+3 ./godot/scripts/bump_android_version.sh
#
# Source of truth: godot/android/version.json (synced into export_presets.cfg).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VER_JSON="$ROOT/godot/android/version.json"
PRESETS="$ROOT/godot/export_presets.cfg"
KIND="${1:-patch}"

python3 - "$VER_JSON" "$PRESETS" "$KIND" "${VERSION_NAME:-}" <<'PY'
import json, re, sys
from pathlib import Path

ver_path, presets_path, kind, override = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4]
data = {"package": "com.toporoom.godot", "versionCode": 1, "versionName": "0.1.0"}
if ver_path.is_file():
    data.update(json.loads(ver_path.read_text()))
code = int(data.get("versionCode", 1)) + 1
name = str(data.get("versionName", "0.1.0"))
if override:
    name = override
else:
    plus = name.split("+", 1)
    core = plus[0]
    build = int(plus[1]) if len(plus) > 1 and plus[1].isdigit() else None
    bits = core.split(".")
    nums = [int(p) if p.isdigit() else 0 for p in bits]
    while len(nums) < 3:
        nums.append(0)
    major, minor, patch = nums[0], nums[1], nums[2]
    if kind == "major":
        name = f"{major + 1}.0.0"
    elif kind == "minor":
        name = f"{major}.{minor + 1}.0"
    elif kind == "build":
        name = f"{major}.{minor}.{patch}+{1 if build is None else build + 1}"
    else:
        name = f"{major}.{minor}.{patch + 1}"
data["package"] = str(data.get("package", "com.toporoom.godot"))
data["versionCode"] = code
data["versionName"] = name
ver_path.parent.mkdir(parents=True, exist_ok=True)
ver_path.write_text(json.dumps(data, indent=2) + "\n")

text = presets_path.read_text()
if not re.search(r"(?m)^version/code=\d+", text):
    raise SystemExit(f"{presets_path} missing version/code")
if not re.search(r'(?m)^version/name=".+"', text):
    raise SystemExit(f"{presets_path} missing version/name")
text = re.sub(r"(?m)^version/code=\d+", f"version/code={code}", text, count=1)
text = re.sub(r'(?m)^version/name=".*"', f'version/name="{name}"', text, count=1)
presets_path.write_text(text)
print(f"Android version → {name} ({code})")
PY
