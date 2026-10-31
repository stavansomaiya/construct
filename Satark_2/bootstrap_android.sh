#!/usr/bin/env bash
# Satark Android setup. Safe to run more than once.
#
# What it does:
#   1. Creates the native android/ folder with your installed Flutter SDK if it is missing.
#   2. Installs Satark's AndroidManifest.xml (share-sheet filters, microphone, package
#      visibility, backup off) and the release-only manifest that removes INTERNET.
#   3. Adds the ML Kit script libraries that release (R8) builds need for Hindi OCR.
# It never touches your Dart code in lib/.
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH. Install Flutter first, then rerun this script."
  exit 1
fi

cd "$(dirname "$0")"

if [[ ! -d android ]]; then
  echo "Generating the native Android project with your installed Flutter SDK..."
  flutter create --platforms=android --org com.satark.app --project-name satark .
fi

mkdir -p android/app/src/main android/app/src/release
cp tool/android/AndroidManifest.main.xml android/app/src/main/AndroidManifest.xml
cp tool/android/AndroidManifest.release.xml android/app/src/release/AndroidManifest.xml
echo "Installed Satark manifests (share sheet, microphone, queries, release without INTERNET)."

python3 - <<'PY'
from pathlib import Path

candidates = [Path('android/app/build.gradle.kts'), Path('android/app/build.gradle')]
gradle_file = next((p for p in candidates if p.exists()), None)
if gradle_file is None:
    raise SystemExit('Could not find android/app/build.gradle(.kts). Add the ML Kit dependencies manually (see README).')

text = gradle_file.read_text()
kts = gradle_file.suffix == '.kts'
wanted = ['chinese', 'japanese', 'korean', 'devanagari']
missing = [s for s in wanted if f'text-recognition-{s}' not in text]
if not missing:
    print('ML Kit script libraries are already present.')
else:
    lines = ''.join(
        (f'    implementation("com.google.mlkit:text-recognition-{s}:16.0.1")\n' if kts
         else f"    implementation 'com.google.mlkit:text-recognition-{s}:16.0.1'\n")
        for s in missing)
    # Top-level `dependencies {` block is the one that starts at column 0.
    marker = '\ndependencies {'
    if marker in text:
        text = text.replace(marker, marker + '\n' + lines.rstrip('\n'), 1)
    else:
        text = text.rstrip('\n') + '\n\ndependencies {\n' + lines + '}\n'
    gradle_file.write_text(text)
    print('Added ML Kit script libraries:', ', '.join(missing))
PY

echo "Android setup is ready. Next: flutter pub get && flutter doctor && flutter run"
