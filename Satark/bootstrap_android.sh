#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH. Install Flutter first, then rerun this script."
  exit 1
fi

cd "$(dirname "$0")"
if [[ ! -d android ]]; then
  echo "Generating the native Android project with your installed Flutter SDK…"
  flutter create --platforms=android --org com.satark.app --project-name satark .
fi

python3 - <<'PY'
from pathlib import Path
import re

# Add the on-device Devanagari text-recognition native dependency.
gradle_candidates = [Path('android/app/build.gradle'), Path('android/app/build.gradle.kts')]
gradle_file = next((p for p in gradle_candidates if p.exists()), None)
if gradle_file is None:
    raise SystemExit('Could not find android/app/build.gradle or build.gradle.kts after flutter create.')
gradle_text = gradle_file.read_text()
if 'text-recognition-devanagari' not in gradle_text:
    if gradle_file.suffix == '.kts':
        line = '    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")\n'
    else:
        line = "    implementation 'com.google.mlkit:text-recognition-devanagari:16.0.1'\n"
    if 'dependencies {' not in gradle_text:
        raise SystemExit(f'Could not find the dependencies block in {gradle_file}. Add the Devanagari ML Kit dependency manually.')
    gradle_text = gradle_text.replace('dependencies {', 'dependencies {\n' + line, 1)
    gradle_file.write_text(gradle_text)
    print(f'Added Hindi/Devanagari OCR dependency to {gradle_file}.')
else:
    print('Hindi/Devanagari OCR dependency is already present.')

# Permissions, share-sheet intent filters, and secure-storage backup protection.
manifest_path = Path('android/app/src/main/AndroidManifest.xml')
manifest = manifest_path.read_text()
permission_entries = [
    ('android.permission.RECORD_AUDIO', '<uses-permission android:name="android.permission.RECORD_AUDIO" />'),
    ('android.permission.READ_EXTERNAL_STORAGE', '<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />'),
]
for permission_name, permission_xml in permission_entries:
    if f'android:name="{permission_name}"' not in manifest:
        # Permissions belong before <queries> when a queries block already exists.
        insertion_point = '<queries' if '<queries' in manifest else '<application'
        manifest = manifest.replace(insertion_point, permission_xml + '\n    ' + insertion_point, 1)

# Avoid a device restore bringing encrypted records back without their key.
if re.search(r'<application\b[^>]*android:allowBackup="true"', manifest):
    manifest = re.sub(r'(android:allowBackup=")true(")', r'\1false\2', manifest, count=1)
elif not re.search(r'<application\b[^>]*android:allowBackup=', manifest):
    manifest = re.sub(r'<application\b', '<application android:allowBackup="false"', manifest, count=1)

# Android's package visibility rules require queries for speech recognition and TTS.
if '<queries>' not in manifest:
    queries_xml = '''
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
    </queries>
'''
    manifest = manifest.replace('<application', queries_xml + '    <application', 1)
else:
    if 'android.speech.RecognitionService' not in manifest:
        speech_query = '''
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
'''
        manifest = manifest.replace('</queries>', speech_query + '    </queries>', 1)
    if 'android.intent.action.TTS_SERVICE' not in manifest:
        tts_query = '''
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
'''
        manifest = manifest.replace('</queries>', tts_query + '    </queries>', 1)

# Use singleTask so incoming share intents can reach the running Flutter activity.
activity_match = re.search(r'<activity\b[^>]*>', manifest)
if activity_match:
    opening = activity_match.group(0)
    if 'android:launchMode=' in opening:
        opening = re.sub(r'android:launchMode="[^"]+"', 'android:launchMode="singleTask"', opening)
    else:
        opening = opening[:-1] + ' android:launchMode="singleTask">'
    manifest = manifest[:activity_match.start()] + opening + manifest[activity_match.end():]

filters_xml = '''
                <intent-filter>
                    <action android:name="android.intent.action.SEND" />
                    <category android:name="android.intent.category.DEFAULT" />
                    <data android:mimeType="text/*" />
                </intent-filter>
                <intent-filter>
                    <action android:name="android.intent.action.SEND" />
                    <category android:name="android.intent.category.DEFAULT" />
                    <data android:mimeType="image/*" />
                </intent-filter>
                <intent-filter>
                    <action android:name="android.intent.action.SEND_MULTIPLE" />
                    <category android:name="android.intent.category.DEFAULT" />
                    <data android:mimeType="image/*" />
                </intent-filter>
                <intent-filter>
                    <action android:name="android.intent.action.SEND" />
                    <category android:name="android.intent.category.DEFAULT" />
                    <data android:mimeType="audio/*" />
                </intent-filter>
                <intent-filter>
                    <action android:name="android.intent.action.VIEW" />
                    <category android:name="android.intent.category.DEFAULT" />
                    <data android:mimeType="*/*" android:scheme="content" />
                </intent-filter>
'''
if 'android.intent.action.SEND' not in manifest:
    manifest = manifest.replace('</activity>', filters_xml + '            </activity>', 1)
manifest_path.write_text(manifest)
print(f'Configured Android permissions and share-sheet intents in {manifest_path}.')
PY

echo "Android setup is ready. Next run: flutter pub get && flutter doctor && flutter run"
