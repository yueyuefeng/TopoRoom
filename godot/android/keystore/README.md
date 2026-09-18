# TopoRoom Android signing

**每次构建升版本；签名固定.**

Do **not** regenerate this keystore. Debug APKs must keep this certificate so
new builds can upgrade over previous installs without uninstalling.

| | |
|---|---|
| File | `godot/android/keystore/debug.keystore` |
| Store password | `android` |
| Key password | `android` |
| Alias | `androiddebugkey` |
| DN | `CN=Android Debug, O=Android, C=US` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |

This is the same key that signed `com.toporoom.godot` **0.1.0** Debug APKs
(2026-09-18). It is committed **only** because this is an OSS debug sideload
app; a Play-store release key must never be generated here or checked in.

`godot/export_credentials.cfg` is generated at export time (absolute path) and
stays gitignored. `./godot/scripts/wire_android_signing.sh` (also run by
`export_android_debug.sh`) always points Godot/Gradle at this file.

Print the cert:

```bash
keytool -list -v \
  -keystore godot/android/keystore/debug.keystore \
  -storepass android -alias androiddebugkey
```
