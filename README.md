# Satark — Android MVP

**Satark** is a multilingual scam-check companion designed to help an older adult pause, examine warning signs, and choose a safe next step before paying, clicking, or sharing information.

The visual direction follows the CoNSTruct 2.0 deck: deep navy, teal and amber, large readable type, rounded cards, and a calm tone.

## What works in this MVP

- **Text triage:** paste or type an SMS, chat, or a short description of a suspicious call. Android share-sheet text and shared images can also be handed into Satark.
- **Screenshot OCR:** choose an image from the phone gallery. Text is extracted on-device using Google ML Kit; English/Latin and Hindi/Devanagari scripts are selectable.
- **Voice input:** short dictation through the phone's speech recognizer, explicitly requesting on-device recognition. This depends on the device and installed offline language packs; if unavailable, use text input. A shared audio/voice-note file is detected, but pre-recorded audio transcription is not implemented yet.
- **English and Hindi results:** risk label, evidence snippets found in the input, explanations, safe next steps, and spoken summary.
- **Five scam families:** digital-arrest / authority impersonation, bank/KYC/OTP, UPI/payment request, courier/parcel, and job/investment patterns.
- **Trusted contact:** store a name and phone number in secure device storage. The result screen asks for confirmation, then opens the phone app; it does not place a call automatically or alert anyone.
- **Optional local history:** off by default. When enabled, recent checks are stored in the platform secure-storage area. Turning it off deletes saved checks. The history screen also has a delete-all action.
- **Sample message:** load a demonstration digital-arrest message to test the main flow.

## Important honesty about the MVP

- The analysis engine in this first build is a **transparent, offline rule-based baseline**, not a trained AI model and not the Gemma 3n model. It detects known phrases and combinations, shows the evidence it matched, and may produce false alarms or miss new scams. The on-device LLM is a later integration task; no large model weights are bundled with this source project.
- The app never reports “guaranteed safe.” A low-warning result only means this simple checker found fewer known patterns.
- Screenshot OCR and rule matching run locally. Speech input requests on-device recognition and does not deliberately fall back to cloud recognition; availability depends on Android's speech service and the downloaded offline language packs. Do not dictate passwords, OTPs, or other highly sensitive data.
- Live call monitoring, automatic family alerts, automatic payment/bank actions, and Marathi are not part of this MVP.

## Requirements for your Mac M4 Pro

1. Install the current stable Flutter SDK (Flutter 3.44+ recommended for the current plugin set) and add `flutter/bin` to your `PATH`.
2. Install Android Studio, including Android SDK, platform tools, and an emulator (or enable USB debugging on your Android phone).
3. From this project folder, run:

   ```bash
   chmod +x bootstrap_android.sh
   ./bootstrap_android.sh
   flutter pub get
   flutter doctor
   flutter run
   ```

   The bootstrap script creates the Android platform scaffold with your installed Flutter SDK and adds the ML Kit Devanagari OCR dependency. It does not overwrite the Dart app source.
4. The bootstrap script also adds Android share-sheet filters for text, screenshots, and files; it requests microphone permission for voice dictation and disables Android backup to avoid restoring secure-storage ciphertext without its key.
5. If `flutter doctor` reports missing Android licences, run `flutter doctor --android-licenses` and accept the licences you agree to.
6. Start an Android emulator or connect your phone, then run `flutter run`.

For a release build, after the debug app runs successfully:

```bash
flutter build apk --release
```

The APK is normally created at `build/app/outputs/flutter-apk/app-release.apk`.

## Run the tests

```bash
flutter test
```

The tests cover digital-arrest escalation, bank/OTP patterns, UPI, the “never guaranteed safe” wording, and Hindi warnings.

## Structure

```text
lib/
  app.dart                      App theme and bottom navigation
  main.dart                     Flutter entry point
  models/analysis_result.dart   Result model and history serialization
  screens/onboarding_screen.dart First-run setup
  screens/check_screen.dart    Text, OCR, voice input, analysis flow
  screens/result_screen.dart   Risk, evidence, actions, speech, trusted contact
  screens/history_screen.dart  Optional local history
  screens/settings_screen.dart Language, contact, privacy settings
  services/local_store.dart    Platform secure storage
  services/ocr_service.dart    On-device ML Kit OCR
  services/scam_analyzer.dart  Explainable local rules for five scam families
test/
  scam_analyzer_test.dart
```

## Before a public release

Do user testing with older adults and consented non-sensitive examples. Add a reviewed and versioned test corpus, false-positive/false-negative measurements, accessibility checks, threat modelling, and a professionally validated on-device model before describing Satark as AI-powered. Never request bank credentials or OTPs in the app.

# construct