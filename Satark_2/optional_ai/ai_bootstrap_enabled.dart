import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import 'ai_engine.dart';

/// OPTIONAL on-device AI. Installed over lib/ai/ai_bootstrap.dart by optional_ai/enable_ai.sh.
///
/// Runs Gemma 4 E2B through LiteRT-LM entirely on the phone. The model file (about 2.6 GB)
/// is downloaded once, over Wi-Fi, when the user taps "Download model" in Settings. After
/// that no network is used. Needs Android 11+ (minSdk 30) and a 64-bit ARM phone.
const String _modelFile = 'gemma-4-E2B-it.litertlm';
const String _modelUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

class GemmaEngine implements AiEngine {
  @override
  String get displayName => 'Gemma 4 E2B';

  @override
  String get sizeLabel => '2.6 GB';

  @override
  Future<bool> isModelInstalled() => FlutterEdgeAi.isModelInstalled(_modelFile);

  @override
  Future<bool> isOnWifi() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);
  }

  @override
  Future<void> installModel({required void Function(int percent) onProgress}) async {
    await FlutterEdgeAi.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromNetwork(_modelUrl).withProgress(onProgress).install();
  }

  @override
  Future<void> removeModel() => FlutterEdgeAi.uninstallModel(_modelFile);

  @override
  Future<String> generate({required String systemInstruction, required String userMessage}) async {
    final model = await FlutterEdgeAi.getActiveModel(maxTokens: 2048);
    final chat = await model.createChat(systemInstruction: systemInstruction);
    await chat.addQueryChunk(Message.text(text: userMessage, isUser: true));
    final reply = StringBuffer();
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) reply.write(response.token);
    }
    return reply.toString();
  }
}

Future<void> initializeOptionalAi() async {
  try {
    await FlutterEdgeAi.initialize(inferenceEngines: const [LiteRtLmEngine()]);
    AiRegistry.engine = GemmaEngine();
  } catch (_) {
    // If the AI runtime cannot start on this phone, Satark simply keeps using its rule checker.
    AiRegistry.engine = null;
  }
}
