# What changed

Merged `Satark-fix-patch.zip` over `Satark-fixed-source.zip` (the two patch uploads were identical), then audited against the agreed MVP.

## Fixes
- Rule engine rewritten: safety-advice sentences no longer trigger scams; "OTP" alone no longer triggers; courier messages no longer also match job scams; fewer false alarms on lone links/police words/Hindi words. Old engine failed 14 of 50 corpus cases, new one passes 50/50 (JS port).
- Manifest: Share-sheet for text/images/audio, `singleTask`, package queries, backups off; release overlay removes INTERNET.
- `bootstrap_android.sh` rewritten and tested (idempotent, installs manifests + ML Kit libs).
- Patch tests would have failed on the OTP-advice and courier cases; fixed.

## Added / improved
- Full Hindi localisation of every screen (`lib/l10n.dart`), language switch everywhere.
- Result screen: colour-coded header, call/WhatsApp trusted contacts, 1930 button, spoken advice.
- Voice-note guidance flow; longer dictation window.
- History: per-entry delete. Settings: AI card, delete-all.
- Optional on-device AI module (`optional_ai/`), pure-Dart prompt/escalation logic with unit tests.
- Kept your extras: multiple contacts, sample message, dual-script OCR, account-restriction rule.

## Not verified
Nothing was compiled (no Flutter SDK in the build sandbox).
