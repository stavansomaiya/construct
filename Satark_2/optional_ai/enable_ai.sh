#!/usr/bin/env bash
# Turns ON the optional on-device AI (Gemma 4 E2B). Safe to run more than once.
# Undo with optional_ai/disable_ai.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -d android ]] || { echo "Run ./bootstrap_android.sh first."; exit 1; }

cp optional_ai/ai_bootstrap_enabled.dart lib/ai/ai_bootstrap.dart

python3 - <<'PY'
import re
from pathlib import Path

# 1. pubspec dependencies
p = Path('pubspec.yaml'); t = p.read_text()
for line in ['  flutter_edge_ai: ^2.5.4', '  flutter_edge_ai_litertlm: ^1.19.0', '  connectivity_plus: ^6.1.0']:
    name = line.split(':')[0].strip()
    if not re.search(rf'^\s*{name}:', t, re.M):
        t = t.replace('\n  receive_sharing_intent:', f'\n{line}\n  receive_sharing_intent:', 1)
t = re.sub(r'sdk: ">=3\.3\.0 <4\.0\.0"', 'sdk: ">=3.12.0 <4.0.0"', t)
p.write_text(t)

# 2. Gradle: minSdk 30 and arm64 only (LiteRT requirement)
g = next(x for x in (Path('android/app/build.gradle.kts'), Path('android/app/build.gradle')) if x.exists())
t = g.read_text(); kts = g.suffix == '.kts'
t = t.replace('minSdk = flutter.minSdkVersion', 'minSdk = 30').replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 30')
if 'arm64-v8a' not in t:
    ndk = '        ndk { abiFilters += listOf("arm64-v8a") }\n' if kts else "        ndk { abiFilters 'arm64-v8a' }\n"
    t = re.sub(r'(defaultConfig\s*\{\n)', r'\1' + ndk, t, count=1)
g.write_text(t)
print('Updated pubspec.yaml and', g)
PY

# 3. Manifest: the model download needs INTERNET once, so keep it in release too.
M=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET' "$M" || \
  sed -i 's#<uses-permission android:name="android.permission.RECORD_AUDIO" />#<uses-permission android:name="android.permission.RECORD_AUDIO" />\n    <uses-permission android:name="android.permission.INTERNET" />#' "$M"
rm -f android/app/src/release/AndroidManifest.xml

echo "Optional AI enabled. Now run: flutter pub get && flutter run --release"
echo "Note: release builds now contain the INTERNET permission (needed once to download the model)."
