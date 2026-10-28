# Satark patch notes

## Changes in this build
- Expanded the courier/parcel rule to recognise wording such as “parcel is on hold”.
- Expanded payment-pressure detection to recognise “Pay ₹25 immediately” and “send the money immediately”.
- Added regression tests for the courier-payment-link and guaranteed-return investment examples.
- Replaced the old template counter widget test (which referenced a nonexistent `MyApp`) with a test for Satark's cautious low-indicator result.

## Important limitations
- Scam analysis is still a transparent rule-based MVP, not a trained AI model. These changes improve two known examples; they do not prove general scam-detection accuracy.
- Imported prerecorded voice-note transcription is not implemented. The app's live speech-to-text feature depends on the Android device's on-device speech recognizer and installed language pack.
- No Flutter SDK is available in the patch-generation environment, so an APK has not been compiled or runtime-tested here.

## Build a release APK on the Mac
From Terminal:

```bash
cd ~/Desktop/construct/Satark
flutter pub get
flutter test
flutter build apk --release
```

If the build succeeds, the APK should be at:

`build/app/outputs/flutter-apk/app-release.apk`

Transfer that file to the Android phone and install it. If Android blocks installation, allow installation from the app used to open the APK, and only install APKs you trust.
