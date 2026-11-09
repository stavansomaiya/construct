# Satark on Replit

## Project choice

Run `Satark_2`, the more complete imported Flutter project. Keep the older
`Satark` directory and supplied source archives unchanged. Do not migrate the
project to a different framework.

## Running

Press Run to launch the **Satark preview** workflow, or run:

```bash
bash scripts/run.sh
```

The script caches Flutter **3.47.9** in ignored `.tooling/flutter`, resolves
the existing Dart dependencies, builds `Satark_2` for web, and serves only
`Satark_2/build/web` on `0.0.0.0:5000`. First startup downloads the SDK and
Flutter web assets; subsequent startups use the cache. Restart the workflow
after Dart edits to rebuild the preview. Generated Flutter output is ignored.

The Nix channel's Flutter 3.32/Dart 3.8 cannot resolve the imported
`receive_sharing_intent` dependency; use `.tooling/flutter/bin/flutter` for all
Flutter commands, not the older bare `flutter` command.

## Checks

```bash
cd Satark_2
../.tooling/flutter/bin/flutter test --no-pub
../.tooling/flutter/bin/flutter analyze --no-pub --no-fatal-infos
../.tooling/flutter/bin/flutter build web --no-pub --no-wasm-dry-run
cd ..
python3 scripts/evaluate_dataset.py
```

The optional evaluation script fetches the public Apache-2.0
`karanverma19/Indian_Multilingual_Scam_Message_Dataset` (120 Hindi, Hinglish,
and English samples), runs the same Dart rule checker used by the app, and
writes `generated-artifacts/benchmark-report.html`. It does not train or modify
the checker. Any non-low risk counts as a scam flag; see the report for
confusion counts and the limitations of this small dataset.

`optional_ai/*.dart` contains inactive copy-in templates, not compilable source
at those paths. They are excluded from analysis; activated code in `lib/ai`
continues to be analyzed. Existing style-level analyzer info messages are
non-blocking.

## Browser vs Android

- Text analysis, English/Hindi, onboarding, trusted contacts, and optional
  history run in the browser using the existing Flutter app.
- Checks use the offline rule engine, not a trained AI model. No API keys or
  external services are needed for this setup.
- Browser storage is specific to this browser/origin. It is not Android secure
  storage; avoid real sensitive messages on shared devices. History is off by
  default. HTTPS is required for the secure-storage web plugin; use Replit's
  HTTPS preview.
- ML Kit screenshot OCR, on-device dictation, and Android share-sheet intake
  require the Android app. Browser buttons explain this rather than invoking
  unsupported plugins. Browser speech recognition is not used as a substitute
  because it may transmit audio to third parties.
- Speech output and phone/WhatsApp links depend on browser voices and installed
  handlers. The Replit preview does not verify native Android integrations.
- The optional AI module remains disabled. Do not enable it or download model
  weights as part of preview setup.

For a real Android build, follow the existing `Satark_2/README.md` on a machine
with Flutter and the Android SDK, and test with a connected phone/emulator.
The Replit workflow is a web preview, not an Android emulator or APK build.
