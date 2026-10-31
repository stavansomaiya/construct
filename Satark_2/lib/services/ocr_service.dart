import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static Future<String> extractText(XFile file, {required String language}) async {
    final inputImage = InputImage.fromFilePath(file.path);
    final preferred = language == 'हिन्दी'
        ? TextRecognitionScript.devanagiri
        : TextRecognitionScript.latin;
    final first = await _recognize(inputImage, preferred);
    final alternate = preferred == TextRecognitionScript.latin
        ? TextRecognitionScript.devanagiri
        : TextRecognitionScript.latin;
    // Screenshots can use a different script from the app UI language. Try both.
    final second = await _recognize(inputImage, alternate);
    return first.trim().length >= second.trim().length
        ? first.trim()
        : second.trim();
  }

  static Future<String> _recognize(InputImage image, TextRecognitionScript script) async {
    final recognizer = TextRecognizer(script: script);
    try {
      final result = await recognizer.processImage(image);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
