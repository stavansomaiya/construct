import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../app.dart';
import '../models/analysis_result.dart';
import '../services/local_store.dart';
import '../services/ocr_service.dart';
import '../services/scam_analyzer.dart';
import 'result_screen.dart';

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key, required this.language, required this.onLanguageChanged});

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<CheckScreen> createState() => CheckScreenState();
}

class CheckScreenState extends State<CheckScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isReadingImage = false;
  bool _isAnalysing = false;
  String? _sourceNote;

  @override
  void dispose() {
    _messageController.dispose();
    _speech.cancel();
    super.dispose();
  }

  /// Called by the app shell when Android shares text or a file into Satark.
  /// Shared images are OCR'd locally. Audio files are detected, but importing
  /// and transcribing a pre-recorded voice note requires a separate offline ASR
  /// model/integration and is deliberately not faked in this MVP.
  Future<void> handleSharedMedia(List<SharedMediaFile> media) async {
    String? importedText;
    String? notice;
    for (final item in media) {
      final mime = (item.mimeType ?? '').toLowerCase();
      if (item.type == SharedMediaType.text || item.type == SharedMediaType.url) {
        importedText = item.path;
        notice = 'Shared text received. Review it before checking.';
        break;
      }
      if (item.type == SharedMediaType.image || mime.startsWith('image/')) {
        try {
          final extracted = await OcrService.extractText(XFile(item.path), language: widget.language);
          importedText = extracted;
          notice = extracted.isEmpty
              ? 'Shared image received, but no readable text was found.'
              : 'Text extracted from the shared image on this device. Review it before checking.';
        } catch (_) {
          notice = 'Shared image received, but OCR could not read it. You can type the message instead.';
        }
        break;
      }
      if (item.type == SharedMediaType.file && mime.startsWith('text/')) {
        try {
          importedText = await File(item.path).readAsString();
          notice = 'Shared text file received. Review it before checking.';
        } catch (_) {
          notice = 'Could not read that shared text file.';
        }
        break;
      }
      if (mime.startsWith('audio/')) {
        notice = 'Voice note received. Direct transcription of imported audio is not enabled yet. Use “Speak message” for on-device live dictation, or type the message.';
      } else {
        notice ??= 'Shared item received, but this file type is not supported yet.';
      }
    }
    if (!mounted) return;
    setState(() {
      if (importedText != null) {
        _messageController.text = importedText!;
        _messageController.selection = TextSelection.collapsed(offset: _messageController.text.length);
      }
      _sourceNote = notice;
    });
  }

  Future<void> _pickScreenshot() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (image == null || !mounted) return;
      setState(() {
        _isReadingImage = true;
        _sourceNote = 'Reading text from image on this device…';
      });
      final extracted = await OcrService.extractText(image, language: widget.language);
      if (!mounted) return;
      setState(() {
        _isReadingImage = false;
        _messageController.text = extracted;
        _sourceNote = extracted.isEmpty
            ? 'No readable text was found. Try a sharper screenshot or type the message.'
            : 'Text extracted on this device. Review it before checking.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isReadingImage = false;
        _sourceNote = 'Image reading failed. Please try another image.';
      });
      _showMessage('Could not extract text from that image.');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            _showMessage('Speech recognition unavailable. Check that an offline language pack is installed.');
          }
        },
      );
      if (!available) {
        _showMessage('Speech recognition is not available on this device. You can type the message instead.');
        return;
      }

      final locales = await _speech.locales();
      final prefix = widget.language == 'हिन्दी' ? 'hi' : 'en';
      final matching = locales.where((locale) => locale.localeId.toLowerCase().startsWith(prefix)).toList();
      if (matching.isEmpty) {
        _showMessage('The selected speech language is not installed. Try typing or change the language in settings.');
        return;
      }
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _messageController.text = result.recognizedWords;
            _messageController.selection = TextSelection.collapsed(offset: _messageController.text.length);
            _sourceNote = 'Voice input captured. Review the transcription before checking.';
          });
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: matching.first.localeId,
          onDevice: true,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
        _showMessage('Could not start offline speech recognition. Type or paste the message instead.');
      }
    }
  }

  Future<void> _analyse() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showMessage('Paste, type, or capture a message before checking it.');
      return;
    }
    setState(() => _isAnalysing = true);
    try {
      final AnalysisResult result = ScamAnalyzer.analyze(text, language: widget.language);
      await LocalStore.saveHistory(result.toJson());
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: result),
      ));
    } finally {
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.language == 'हिन्दी';
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(backgroundColor: satarkTeal, radius: 18, child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
            SizedBox(width: 10),
            Text('Satark', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: DropdownButton<String>(
                value: widget.language,
                dropdownColor: Colors.white,
                underline: const SizedBox.shrink(),
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'हिन्दी', child: Text('हिन्दी')),
                ],
                onChanged: (value) {
                  if (value != null) widget.onLanguageChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: satarkNavy,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(color: satarkAmber, borderRadius: BorderRadius.circular(30)),
                      child: Text(isHindi ? 'रुकें • जाँचें • सुरक्षित रहें' : 'PAUSE  •  CHECK  •  PROTECT',
                          style: const TextStyle(color: satarkNavy, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isHindi ? 'पैसे भेजने से पहले एक पल रुकें।' : 'Pause before you pay, click, or share.',
                      style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isHindi
                          ? 'संदेश जाँचें और समझें कि कौन-से संकेत संदिग्ध हो सकते हैं।'
                          : 'Check a suspicious message and see which signs deserve a closer look.',
                      style: const TextStyle(color: Color(0xFFE4E8F4), fontSize: 15, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(isHindi ? 'संदेश जोड़ें' : 'Add a message', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                isHindi ? 'टेक्स्ट लिखें, स्क्रीनशॉट चुनें या बोलकर दर्ज करें।' : 'Type or paste text, choose a screenshot, or dictate a short message.',
                style: const TextStyle(color: Color(0xFF626A7F), fontSize: 14),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _messageController.text = isHindi
                          ? 'मैं सीबीआई अधिकारी बोल रहा हूँ। आपके नाम पर केस दर्ज है। कॉल मत काटना और गिरफ्तारी से बचने के लिए अभी पैसे ट्रांसफर करें। किसी को मत बताना।'
                          : 'I am calling from the CBI. A case has been registered in your name. Do not disconnect. Transfer money now to avoid arrest and do not tell anyone.';
                      _sourceNote = 'Sample message loaded. This is an example for testing, not a real alert.';
                    });
                  },
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(isHindi ? 'उदाहरण आज़माएँ' : 'Try a sample message'),
                  style: TextButton.styleFrom(foregroundColor: satarkTeal),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _messageController,
                minLines: 6,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isHindi
                      ? 'संदिग्ध संदेश यहाँ पेस्ट करें…'
                      : 'Paste a message, SMS, chat, or a short description of a call…',
                  hintStyle: const TextStyle(color: Color(0xFF8D93A3)),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() => _sourceNote = null),
              ),
              if (_sourceNote != null) ...[
                const SizedBox(height: 8),
                Text(_sourceNote!, style: const TextStyle(color: satarkTeal, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isReadingImage ? null : _pickScreenshot,
                      icon: _isReadingImage
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.image_outlined),
                      label: Text(isHindi ? 'स्क्रीनशॉट' : 'Screenshot'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: satarkNavy,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFFD5D8DF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleListening,
                      icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic_none),
                      label: Text(_isListening ? (isHindi ? 'रोकें' : 'Stop listening') : (isHindi ? 'बोलकर लिखें' : 'Speak message')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isListening ? const Color(0xFFB3261E) : satarkNavy,
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: _isListening ? const Color(0xFFB3261E) : const Color(0xFFD5D8DF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _isAnalysing ? null : _analyse,
                icon: _isAnalysing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.shield_outlined),
                label: Text(isHindi ? 'संदेश की जाँच करें' : 'Check this message'),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, color: satarkTeal, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isHindi
                              ? 'जाँच डिवाइस पर चलती है। बोलकर लिखने के लिए डिवाइस की ऑफलाइन भाषा सुविधा उपलब्ध होना ज़रूरी है।'
                              : 'Text analysis and screenshot OCR run on-device. Voice input requests on-device speech recognition; an offline language pack may be required.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF555E73), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Checks currently cover digital-arrest impersonation, bank/KYC/OTP, UPI, courier/parcel, and job/investment patterns.',
                  style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF757C8E))),
            ],
          ),
        ),
      ),
    );
  }
}
