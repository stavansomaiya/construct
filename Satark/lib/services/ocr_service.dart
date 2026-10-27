import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static Future<String> extractText(XFile file, {required String language}) async {
    final script = language == 'हिन्दी'
        ? TextRecognitionScript.devanagiri
        : TextRecognitionScript.latin;
    final recognizer = TextRecognizer(script: script);
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final result = await recognizer.processImage(inputImage);
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
