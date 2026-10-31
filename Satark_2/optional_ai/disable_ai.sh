#!/usr/bin/env bash
# Turns the optional on-device AI OFF and restores the network-free default build.
set -euo pipefail
cd "$(dirname "$0")/.."

cp optional_ai/ai_bootstrap_disabled.dart lib/ai/ai_bootstrap.dart

python3 - <<'PY'
import re
from pathlib import Path
p = Path('pubspec.yaml'); t = p.read_text()
for name in ['flutter_edge_ai', 'flutter_edge_ai_litertlm', 'connectivity_plus']:
    t = re.sub(rf'^\s*{name}:.*\n', '', t, flags=re.M)
t = t.replace('sdk: ">=3.12.0 <4.0.0"', 'sdk: ">=3.3.0 <4.0.0"')
p.write_text(t)
g = next(x for x in (Path('android/app/build.gradle.kts'), Path('android/app/build.gradle')) if x.exists())
t = g.read_text()
t = t.replace('minSdk = 30', 'minSdk = flutter.minSdkVersion').replace('minSdkVersion 30', 'minSdkVersion flutter.minSdkVersion')
t = re.sub(r'^\s*ndk \{ abiFilters.*\n', '', t, flags=re.M)
g.write_text(t)
PY

M=android/app/src/main/AndroidManifest.xml
sed -i '/android.permission.INTERNET/d' "$M"
mkdir -p android/app/src/release
cp tool/android/AndroidManifest.release.xml android/app/src/release/AndroidManifest.xml

echo "Optional AI disabled. Now run: flutter pub get && flutter run"
