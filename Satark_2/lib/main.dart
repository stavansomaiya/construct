import 'package:flutter/material.dart';

import 'ai/ai_bootstrap.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No-op in the default build. Registers the on-device AI engine when it is enabled.
  await initializeOptionalAi();
  runApp(const SatarkApp());
}
