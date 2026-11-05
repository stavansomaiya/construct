import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../ai/ai_engine.dart';
import '../app.dart';
import '../l10n.dart';
import '../models/analysis_result.dart';
import '../services/local_store.dart';
import '../services/ocr_service.dart';
import '../services/scam_analyzer.dart';
import 'result_screen.dart';

// ---------------------------------------------------------------------------
// Preferred locale IDs tried in order. The first one that actually exists on
// the device wins. Falling back to '' lets the platform pick any locale.
// ---------------------------------------------------------------------------
const List<String> _kEnglishLocales = ['en_IN', 'en_US', 'en_GB', 'en_AU', 'en'];
const List<String> _kHindiLocales   = ['hi_IN', 'hi'];

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key, required this.language, required this.onLanguageChanged});

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<CheckScreen> createState() => CheckScreenState();
}

class CheckScreenState extends State<CheckScreen> {
  // ── Text / image input ──────────────────────────────────────────────────
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isReadingImage = false;
  bool _isAnalysing   = false;
  bool _voiceNotePending = false;
  String? _sourceNote;

  // ── Speech-to-text ──────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// True while we are actively recording audio.
  bool _isListening = false;

  /// True while [_speech.initialize()] is in progress on first tap.
  bool _speechInitialising = false;

  /// Set to true once [_speech.initialize()] returns (success or failure).
  bool _speechReady = false;

  /// Whether the device was confirmed to have any usable speech locale.
  bool _speechAvailable = false;

  /// Text that existed before the current listening session started —
  /// recognised words are appended to it.
  String _voiceBase = '';

  String get _lang => widget.language;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _messageController.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Shared-media handling ────────────────────────────────────────────────

  bool _looksLikeAudio(SharedMediaFile item) {
    final mime = (item.mimeType ?? '').toLowerCase();
    if (mime.startsWith('audio/')) return true;
    final path = item.path.toLowerCase();
    return path.endsWith('.opus') ||
        path.endsWith('.ogg')  ||
        path.endsWith('.m4a')  ||
        path.endsWith('.mp3')  ||
        path.endsWith('.aac')  ||
        path.endsWith('.amr')  ||
        path.endsWith('.wav');
  }

  /// Called by the app shell when Android shares text, images, or a voice
  /// note into Satark.
  Future<void> handleSharedMedia(List<SharedMediaFile> media) async {
    String? importedText;
    String? notice;
    var voiceNote = false;
    final images = <SharedMediaFile>[];

    for (final item in media) {
      final mime = (item.mimeType ?? '').toLowerCase();
      if (item.type == SharedMediaType.text || item.type == SharedMediaType.url) {
        importedText = item.path;
        notice = tr(_lang,
            'Shared text received. Review it before checking.',
            'साझा किया गया टेक्स्ट मिल गया। जाँचने से पहले उसे देख लें।');
        images.clear();
        break;
      }
      if (item.type == SharedMediaType.image || mime.startsWith('image/')) {
        images.add(item);
        continue;
      }
      if (item.type == SharedMediaType.file && mime.startsWith('text/')) {
        try {
          importedText = await File(item.path).readAsString();
          notice = tr(_lang,
              'Shared text file received. Review it before checking.',
              'साझा की गई टेक्स्ट फ़ाइल मिल गई। जाँचने से पहले उसे देख लें।');
        } catch (_) {
          notice = tr(_lang,
              'Could not read that shared text file.',
              'वह साझा की गई टेक्स्ट फ़ाइल पढ़ी नहीं जा सकी।');
        }
        break;
      }
      if (_looksLikeAudio(item)) {
        voiceNote = true;
        continue;
      }
      notice ??= tr(_lang,
          'Shared item received, but this file type is not supported yet.',
          'साझा की गई चीज़ मिली, पर इस तरह की फ़ाइल अभी समर्थित नहीं है।');
    }

    if (importedText == null && images.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isReadingImage = true;
          _sourceNote = tr(_lang,
              'Reading text from the shared image on this phone…',
              'साझा की गई तस्वीर से इसी फ़ोन पर टेक्स्ट पढ़ा जा रहा है…');
        });
      }
      final pieces = <String>[];
      try {
        for (final image in images.take(3)) {
          final extracted =
              await OcrService.extractText(XFile(image.path), language: _lang);
          if (extracted.isNotEmpty) pieces.add(extracted);
        }
        importedText = pieces.join('\n\n');
        notice = importedText.isEmpty
            ? tr(_lang,
                'Shared image received, but no readable text was found.',
                'साझा की गई तस्वीर मिली, पर उसमें पढ़ने लायक टेक्स्ट नहीं मिला।')
            : tr(_lang,
                'Text extracted from the shared image on this phone. Review it before checking.',
                'साझा की गई तस्वीर से इसी फ़ोन पर टेक्स्ट निकाला गया। जाँचने से पहले उसे देख लें।');
      } catch (_) {
        notice = tr(_lang,
            'Shared image received, but OCR could not read it. You can type the message instead.',
            'साझा की गई तस्वीर मिली, पर उसे पढ़ा नहीं जा सका। आप संदेश लिख सकते हैं।');
      }
    }

    if (voiceNote && importedText == null) {
      notice = tr(
        _lang,
        'Voice note received. Satark cannot read the audio file itself yet. '
        'Tap "Start listening", then play the voice note on speaker near the phone.',
        'वॉइस नोट मिल गया। सतर्क अभी ऑडियो फ़ाइल सीधे नहीं पढ़ सकता। '
        '"सुनना शुरू करें" दबाएँ, फिर वॉइस नोट को स्पीकर पर फ़ोन के पास बजाएँ।',
      );
    }

    if (!mounted) return;
    setState(() {
      _isReadingImage    = false;
      _voiceNotePending  = voiceNote && importedText == null;
      if (importedText != null) {
        _messageController.text = importedText;
        _messageController.selection =
            TextSelection.collapsed(offset: _messageController.text.length);
      }
      _sourceNote = notice;
    });
  }

  // ── OCR ──────────────────────────────────────────────────────────────────

  Future<void> _pickScreenshot() async {
    try {
      final image = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 100);
      if (image == null || !mounted) return;
      setState(() {
        _isReadingImage = true;
        _sourceNote = tr(_lang,
            'Reading text from the image on this phone…',
            'तस्वीर से इसी फ़ोन पर टेक्स्ट पढ़ा जा रहा है…');
      });
      final extracted = await OcrService.extractText(image, language: _lang);
      if (!mounted) return;
      setState(() {
        _isReadingImage = false;
        _messageController.text = extracted;
        _sourceNote = extracted.isEmpty
            ? tr(_lang,
                'No readable text was found. Try a sharper screenshot or type the message.',
                'पढ़ने लायक टेक्स्ट नहीं मिला। साफ़ स्क्रीनशॉट चुनें या संदेश लिखें।')
            : tr(_lang,
                'Text extracted on this phone. Review it before checking.',
                'टेक्स्ट इसी फ़ोन पर निकाला गया। जाँचने से पहले उसे देख लें।');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isReadingImage = false;
        _sourceNote = tr(_lang,
            'Image reading failed. Please try another image.',
            'तस्वीर पढ़ने में दिक्कत आई। कृपया दूसरी तस्वीर चुनें।');
      });
      _showMessage(tr(_lang,
          'Could not extract text from that image.',
          'उस तस्वीर से टेक्स्ट नहीं निकल सका।'));
    }
  }

  // ── Speech-to-text ───────────────────────────────────────────────────────

  /// Lazily initialises [_speech] on the first "Speak message" tap.
  /// Returns true if speech is usable, false otherwise.
  Future<bool> _ensureSpeechInitialised() async {
    if (_speechReady) return _speechAvailable;
    if (_speechInitialising) return false; // already in-flight, ignore double-tap

    setState(() => _speechInitialising = true);

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          // 'done' / 'notListening' mean the recogniser stopped on its own.
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          // Silently absorb errors; the user will just see listening stop.
          if (mounted) setState(() => _isListening = false);
        },
      );
      _speechAvailable = available;
    } catch (_) {
      _speechAvailable = false;
    } finally {
      _speechReady = true;
      if (mounted) setState(() => _speechInitialising = false);
    }
    return _speechAvailable;
  }

  /// Picks the best available locale for [language] from those installed on
  /// the device. Returns '' (empty string) as an unconditional fallback so
  /// [_speech.listen()] always gets a valid value.
  Future<String?> _bestLocaleId(String language) async {
    try {
      final locales = await _speech.locales();
      final ids = locales.map((l) => l.localeId).toList();
      final preferred =
          isHindi(language) ? _kHindiLocales : _kEnglishLocales;
      for (final want in preferred) {
        // Case-insensitive prefix match so 'en_IN' matches 'en_in' or 'en-IN'.
        final match = ids.firstWhere(
          (id) => id.toLowerCase().replaceAll('-', '_').startsWith(
                want.toLowerCase().replaceAll('-', '_')),
          orElse: () => '',
        );
        if (match.isNotEmpty) return match;
      }
    } catch (_) {
      // On some emulators locales() throws; treat as "no preference".
    }
    return null; // null → let the platform choose its default
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    // ── Stop ────────────────────────────────────────────────────────────
    if (_isListening) {
      await _stopListening();
      return;
    }

    // ── Initialise on first use ──────────────────────────────────────────
    final ok = await _ensureSpeechInitialised();
    if (!ok) {
      _showMessage(tr(
        _lang,
        'Voice input is not available on this device or emulator. '
        'You can type or paste the message instead.',
        'इस फ़ोन या एमुलेटर पर आवाज़ इनपुट उपलब्ध नहीं है। '
        'संदेश लिखें या पेस्ट करें।',
      ));
      return;
    }

    // ── Pick locale & start ──────────────────────────────────────────────
    final localeId = await _bestLocaleId(_lang);
    _voiceBase = _messageController.text.trim();

    setState(() {
      _isListening      = true;
      _voiceNotePending = false;
      _sourceNote = tr(_lang,
          'Listening… speak clearly near the phone.',
          'सुन रहा हूँ… फ़ोन के पास साफ़ बोलें।');
    });

    try {
      await _speech.listen(
        localeId: localeId,
        listenFor:    const Duration(seconds: 120),
        pauseFor:     const Duration(seconds: 6),
        partialResults: true,
        onResult: (result) {
          if (!mounted) return;
          final heard = result.recognizedWords;
          final combined =
              _voiceBase.isEmpty ? heard : '$_voiceBase $heard';
          setState(() {
            _messageController.value = TextEditingValue(
              text: combined,
              selection: TextSelection.collapsed(offset: combined.length),
            );
            _sourceNote = tr(_lang,
                'Voice input captured. Review the transcription before checking.',
                'आवाज़ से लिखा गया टेक्स्ट मिल गया। जाँचने से पहले उसे देख लें।');
            // Once we get a final result, update the base so the next
            // partial still appends correctly.
            if (result.finalResult) {
              _voiceBase = combined.trim();
              _isListening = false;
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenFor:  const Duration(seconds: 120),
          pauseFor:   const Duration(seconds: 6),
          // onDevice:true removed — it fails silently on many emulators and
          // some physical devices without the offline pack.  We rely on
          // whatever the system speech engine offers.
        ),
      );
    } catch (_) {
      // listen() can throw on some emulators even after a successful init.
      if (mounted) {
        setState(() => _isListening = false);
        _showMessage(tr(
          _lang,
          'Could not start voice recognition. Type or paste the message instead.',
          'आवाज़ पहचान शुरू नहीं हो सकी। संदेश लिखें या पेस्ट करें।',
        ));
      }
    }
  }

  // ── Voice-note help dialog ───────────────────────────────────────────────

  Future<void> _showVoiceNoteHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(_lang, 'Checking a voice note', 'वॉइस नोट कैसे जाँचें')),
        content: Text(tr(
          _lang,
          '1. Tap "Speak message" (or "Start listening").\n'
          '2. Play the voice note on speaker, close to this phone.\n'
          '3. Check the text that appears, then tap "Check this message".\n\n'
          'Everything stays on this phone. Satark cannot yet read a voice-note '
          'file directly, so it listens to it like it listens to you.',
          '1. "बोलकर लिखें" (या "सुनना शुरू करें") दबाएँ।\n'
          '2. वॉइस नोट को स्पीकर पर इस फ़ोन के पास बजाएँ।\n'
          '3. जो टेक्स्ट दिखे उसे देखें, फिर "संदेश की जाँच करें" दबाएँ।\n\n'
          'सब कुछ इसी फ़ोन पर रहता है। सतर्क अभी वॉइस नोट की फ़ाइल सीधे '
          'नहीं पढ़ सकता, इसलिए वह उसे वैसे ही सुनता है जैसे आपको सुनता है।',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(_lang, 'OK', 'ठीक है')),
          ),
        ],
      ),
    );
  }

  // ── Analysis ─────────────────────────────────────────────────────────────

  Future<void> _analyse() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showMessage(tr(
        _lang,
        'Paste, type, or capture a message before checking it.',
        'जाँचने से पहले संदेश पेस्ट करें, लिखें या स्क्रीनशॉट/आवाज़ से जोड़ें।',
      ));
      return;
    }
    if (_isListening) await _stopListening();

    setState(() => _isAnalysing = true);
    try {
      final AnalysisResult rules = ScamAnalyzer.analyze(text, language: _lang);
      final AnalysisResult result = await AiAssistant.refine(rules);
      await LocalStore.saveHistory(result.toJson());
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: result),
      ));
    } finally {
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hindi = isHindi(_lang);

    // Voice button appearance driven by state machine.
    final bool voiceButtonBusy = _speechInitialising;
    final String voiceLabel;
    final Color  voiceFg;
    final Color  voiceBorder;
    final Widget voiceIcon;

    if (voiceButtonBusy) {
      voiceLabel  = tr(_lang, 'Please wait…', 'कृपया प्रतीक्षा करें…');
      voiceFg     = const Color(0xFF8D93A3);
      voiceBorder = const Color(0xFFD5D8DF);
      voiceIcon   = const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else if (_isListening) {
      voiceLabel  = tr(_lang, 'Stop listening', 'रोकें');
      voiceFg     = const Color(0xFFB3261E);
      voiceBorder = const Color(0xFFB3261E);
      voiceIcon   = const Icon(Icons.stop_circle_outlined);
    } else {
      voiceLabel  = tr(_lang, 'Speak message', 'बोलकर लिखें');
      voiceFg     = satarkNavy;
      voiceBorder = const Color(0xFFD5D8DF);
      voiceIcon   = const Icon(Icons.mic_none);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: satarkTeal,
              radius: 18,
              child: Text('S',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            SizedBox(width: 10),
            Text('Satark',
                style: TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: DropdownButton<String>(
                value: _lang,
                dropdownColor: Colors.white,
                underline: const SizedBox.shrink(),
                iconEnabledColor: Colors.white,
                selectedItemBuilder: (context) => const [
                  Center(
                      child: Text('English',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                  Center(
                      child: Text('हिन्दी',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                ],
                style: const TextStyle(
                    color: satarkNavy, fontWeight: FontWeight.w700),
                items: const [
                  DropdownMenuItem(value: kEnglish, child: Text('English')),
                  DropdownMenuItem(value: kHindi,   child: Text('हिन्दी')),
                ],
                onChanged: (value) {
                  if (value != null) widget.onLanguageChanged(value);
                },
              ),
            ),
          ),
        ],
      ),

      // ─────────────────────────────────────────────────────────────────
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Hero banner ────────────────────────────────────────────
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                          color: satarkAmber,
                          borderRadius: BorderRadius.circular(30)),
                      child: Text(
                        hindi
                            ? 'रुकें • जाँचें • सुरक्षित रहें'
                            : 'PAUSE  •  CHECK  •  PROTECT',
                        style: const TextStyle(
                            color: satarkNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      hindi
                          ? 'पैसे भेजने से पहले एक पल रुकें।'
                          : 'Pause before you pay, click, or share.',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hindi
                          ? 'संदेश जाँचें और समझें कि कौन-से संकेत संदिग्ध हो सकते हैं।'
                          : 'Check a suspicious message and see which signs deserve a closer look.',
                      style: const TextStyle(
                          color: Color(0xFFE4E8F4),
                          fontSize: 15,
                          height: 1.45),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Text(hindi ? 'संदेश जोड़ें' : 'Add a message',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                hindi
                    ? 'टेक्स्ट लिखें, स्क्रीनशॉट चुनें, बोलकर दर्ज करें, या WhatsApp आदि से "शेयर" करें।'
                    : 'Type or paste text, choose a screenshot, dictate it, or use "Share" from WhatsApp and other apps.',
                style: const TextStyle(
                    color: Color(0xFF626A7F), fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 10),

              // ── Sample message ─────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _messageController.text = hindi
                          ? 'मैं सीबीआई अधिकारी बोल रहा हूँ। आपके नाम पर केस दर्ज है। कॉल मत काटना और गिरफ्तारी से बचने के लिए अभी पैसे ट्रांसफर करें। किसी को मत बताना।'
                          : 'I am calling from the CBI. A case has been registered in your name. Do not disconnect. Transfer money now to avoid arrest and do not tell anyone.';
                      _sourceNote = tr(
                        _lang,
                        'Sample message loaded. This is an example for testing, not a real alert.',
                        'उदाहरण संदेश लोड हुआ। यह केवल जाँच के लिए है, असली अलर्ट नहीं।',
                      );
                    });
                  },
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(hindi ? 'उदाहरण आज़माएँ' : 'Try a sample message'),
                  style: TextButton.styleFrom(foregroundColor: satarkTeal),
                ),
              ),

              const SizedBox(height: 4),

              // ── Message text field ─────────────────────────────────────
              TextField(
                controller: _messageController,
                minLines: 6,
                maxLines: 10,
                style: const TextStyle(fontSize: 17, height: 1.4),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: hindi
                      ? 'संदिग्ध संदेश यहाँ पेस्ट करें…'
                      : 'Paste a message, SMS, chat, or a short description of a call…',
                  hintStyle:
                      const TextStyle(color: Color(0xFF8D93A3)),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) =>
                    setState(() => _sourceNote = null),
              ),

              if (_sourceNote != null) ...[
                const SizedBox(height: 8),
                Text(_sourceNote!,
                    style: const TextStyle(
                        color: satarkTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],

              // ── Voice-note guidance card ───────────────────────────────
              if (_voiceNotePending) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.graphic_eq,
                              color: satarkTeal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hindi
                                  ? 'वॉइस नोट मिला'
                                  : 'Voice note received',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          hindi
                              ? 'वॉइस नोट को स्पीकर पर फ़ोन के पास बजाएँ। सतर्क उसे इसी फ़ोन पर सुनकर टेक्स्ट बना देगा।'
                              : 'Play the voice note on speaker near the phone. Satark will listen on this phone and turn it into text.',
                          style:
                              const TextStyle(fontSize: 14, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: voiceButtonBusy ? null : _toggleListening,
                          icon: const Icon(Icons.mic),
                          label: Text(
                              hindi ? 'सुनना शुरू करें' : 'Start listening'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ── Screenshot + Voice buttons ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isReadingImage ? null : _pickScreenshot,
                      icon: _isReadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.image_outlined),
                      label: Text(hindi ? 'स्क्रीनशॉट' : 'Screenshot'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: satarkNavy,
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(
                            color: Color(0xFFD5D8DF)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: voiceButtonBusy ? null : _toggleListening,
                      icon: voiceIcon,
                      label: Text(voiceLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: voiceFg,
                        minimumSize: const Size.fromHeight(56),
                        side: BorderSide(color: voiceBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showVoiceNoteHelp,
                  icon: const Icon(Icons.graphic_eq, size: 18),
                  label: Text(hindi
                      ? 'वॉइस नोट कैसे जाँचें?'
                      : 'How do I check a voice note?'),
                  style: TextButton.styleFrom(
                      foregroundColor: satarkTeal),
                ),
              ),

              const SizedBox(height: 6),

              // ── Analyse button ─────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isAnalysing ? null : _analyse,
                icon: _isAnalysing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.shield_outlined),
                label: Text(_isAnalysing
                    ? (hindi
                        ? 'इसी फ़ोन पर जाँच हो रही है…'
                        : 'Checking on this phone…')
                    : (hindi
                        ? 'संदेश की जाँच करें'
                        : 'Check this message')),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60)),
              ),

              const SizedBox(height: 18),

              // ── Privacy card ───────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline,
                          color: satarkTeal, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hindi
                              ? 'जाँच इसी फ़ोन पर चलती है और आपका संदेश कहीं नहीं भेजा जाता। बोलकर लिखने के लिए फ़ोन की भाषा सुविधा ज़रूरी है।'
                              : "Checks run on this phone and your message is never sent anywhere. Voice input uses the phone's speech service.",
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF555E73),
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                hindi
                    ? 'जाँच इन पर केंद्रित है: डिजिटल अरेस्ट, बैंक/केवाईसी/ओटीपी, यूपीआई, कूरियर/पार्सल और नौकरी/निवेश।'
                    : 'Checks cover digital-arrest impersonation, bank/KYC/OTP, UPI, courier/parcel, and job/investment patterns.',
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF757C8E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
