# Satark — Android scam-check companion (MVP)

Satark helps an older adult **pause, check and protect** before paying, clicking or sharing
information. It runs on the phone, never says a message is "safe", and never alerts anyone on its own.
Look: navy / teal / amber, from the CoNSTruct 2.0 deck.

## What it does

- **Three ways in:** paste/type text, pick a screenshot (on-device OCR, English + Devanagari), or speak (on-device dictation).
  All three also work from the Android **Share** sheet (WhatsApp, SMS, Gallery, voice notes).
- **Voice notes:** Satark cannot yet transcribe an audio *file*. It guides the user to play the note on speaker while
  the phone listens (same dictation as "Speak message"). True file transcription (Whisper/Vosk) is a later upgrade.
- **Five scam families:** digital arrest, bank/KYC/OTP, UPI, courier/parcel, job/investment.
- **Transparent rule engine** (`lib/services/scam_analyzer.dart`): weighted patterns, shows the exact evidence it matched,
  ignores sentences that *warn* against scams ("never share your OTP"). Result: HIGH RISK / CHECK CAREFULLY / FEWER WARNING SIGNS.
- **Large colour-coded result screen** in English or Hindi, spoken advice (TTS), 1930 cyber-crime helpline button.
- **Trusted contacts** (several, stored in secure storage): buttons open the dialer or WhatsApp with a ready note after you confirm. Nothing is sent automatically.
- **Optional encrypted history** (off by default), delete one entry or all.
- **Optional on-device AI** (`optional_ai/`, off by default): Gemma 4 E2B explains the message in plain words and may *raise* the
  risk one step. It can never lower a rule-based warning.
- **Privacy:** no analytics, backups off, and the release APK has the INTERNET permission removed (default build).

Not in the MVP: live call monitoring, automatic family alerts, Marathi.

## Build on your Mac

1. Install Flutter (stable), Android Studio (SDK + platform tools), enable USB debugging on the phone.
2. In this folder:
   ```bash
   chmod +x bootstrap_android.sh
   ./bootstrap_android.sh      # creates android/, installs manifests, ML Kit script libs
   flutter pub get
   flutter doctor
   flutter run                 # phone connected
   flutter test                # rule-engine corpus (50 cases) + AI prompt tests
   flutter build apk --release # build/app/outputs/flutter-apk/app-release.apk
   ```
3. Test **on a physical phone**: share-sheet, OCR and offline dictation (install the Hindi/English offline speech packs) don't work properly on emulators.

## Optional AI

See `optional_ai/README.md`. Run `./optional_ai/enable_ai.sh`, `flutter pub get`, then download the model from Settings over Wi-Fi.

## Honest status

The project was assembled and reviewed **without a Flutter SDK available**, so it has not been compiled. Expect the occasional
small compile error on the first `flutter run`; paste it back and it is usually a one-line fix. The rule engine logic was verified
with an equivalent JavaScript port against the 50-case corpus (`test/corpus/messages.json`).

## Layout

- `lib/services/scam_analyzer.dart` rules · `lib/models/analysis_result.dart` · `lib/l10n.dart` English/Hindi helper
- `lib/screens/` check, result, history, settings, onboarding · `lib/ai/` AI interface + prompt logic
- `lib/services/` OCR, secure storage · `optional_ai/` Gemma engine and enable/disable scripts
- `tool/android/` manifests copied by the bootstrap script · `PATCH_NOTES.md` what changed vs your zips
