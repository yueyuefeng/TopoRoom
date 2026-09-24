#!/usr/bin/env bash
# Point Godot export_credentials.cfg at the committed project debug keystore.
# Never generate a new debug key. Fail if the cert fingerprint drifts.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
KS="$ROOT/godot/android/keystore/debug.keystore"
EXPECT_FILE="$ROOT/godot/android/keystore/debug.cert.sha256"
CREDS="$ROOT/godot/export_credentials.cfg"
ALIAS="${TOPOROOM_DEBUG_KEY_ALIAS:-androiddebugkey}"
PASS="${TOPOROOM_DEBUG_KEY_PASS:-android}"

if [[ ! -f "$KS" ]]; then
  echo "Missing committed debug keystore: $KS" >&2
  echo "Do not keytool -genkeypair. Restore godot/android/keystore/debug.keystore from git." >&2
  exit 1
fi

got="$(
  keytool -list -v -keystore "$KS" -storepass "$PASS" -alias "$ALIAS" 2>/dev/null \
  | python3 -c "import sys,re; m=re.search(r'SHA256:\\s*([0-9A-Fa-f:]+)', sys.stdin.read()); print(m.group(1).replace(':','').lower() if m else '')"
)"
expect="$(tr -d '[:space:]:' < "$EXPECT_FILE" | tr 'A-F' 'a-f')"
if [[ -z "$got" || "$got" != "$expect" ]]; then
  echo "Debug keystore cert SHA-256 mismatch." >&2
  echo "  expected $expect" >&2
  echo "  got      ${got:-<none>}" >&2
  echo "Refusing to export with a different key." >&2
  exit 1
fi

cat > "$CREDS" <<EOF
[preset.0]

script_encryption_key=""

[preset.0.options]

keystore/debug="$KS"
keystore/debug_user="$ALIAS"
keystore/debug_password="$PASS"
keystore/release=""
keystore/release_user=""
keystore/release_password=""
EOF

echo "Wired debug signing → $KS"
echo "Cert SHA-256 $got"
