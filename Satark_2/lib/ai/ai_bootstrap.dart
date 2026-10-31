import 'ai_engine.dart';

/// Default build: no on-device AI model is wired in, so Satark uses its rule checker only
/// and the release app has no network permission.
///
/// To try the optional on-device AI (Gemma), run `optional_ai/enable_ai.sh`. It replaces this
/// file with `optional_ai/ai_bootstrap_enabled.dart`, which registers a real engine.
/// `optional_ai/disable_ai.sh` puts this file back.
Future<void> initializeOptionalAi() async {
  AiRegistry.engine = null;
}
