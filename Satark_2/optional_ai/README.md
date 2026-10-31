# Optional on-device AI (Gemma 4 E2B)

Default Satark = rule checker only. This module adds a small language model that runs **on the phone**.

## Enable / disable
```bash
./optional_ai/enable_ai.sh && flutter pub get && flutter run --release
./optional_ai/disable_ai.sh   # back to the network-free build
```
Then open **Settings → On-device AI helper → Download model (Wi-Fi)**. The model is ~2.6 GB, downloaded once from Hugging Face
(public, no token). After that it works offline.

## Requirements and caveats
- Android 11+ (minSdk 30), 64-bit ARM phone, 8 GB RAM recommended. The script sets minSdk 30 and arm64-only for you.
- Needs a Flutter/Dart version new enough for `flutter_edge_ai` (Dart 3.12+, Flutter 3.44+). Run `flutter upgrade` if pub complains.
- **Enabled builds include the INTERNET permission** (to download the model). Disabled builds do not.
- The AI sees at most 1500 characters of the message, which is marked as untrusted text. Its answer is parsed strictly; anything odd is ignored.
- It can only raise risk (review → high, low → review). It never lowers a rule warning. If it times out (90 s) the rule result is shown.
- The engine code was written against the package source (v2.5.4) but **not compiled** here; expect to fix small API differences.
