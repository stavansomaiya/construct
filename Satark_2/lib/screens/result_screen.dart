import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../l10n.dart';
import '../models/analysis_result.dart';
import '../services/local_store.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result});

  final AnalysisResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  List<Map<String, String>> _contacts = [];

  String get _lang => widget.result.language;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await LocalStore.getContacts();
    if (mounted) setState(() => _contacts = contacts);
  }

  // The big coloured header is the main "how worried should I be" signal.
  Color get _headerColor {
    switch (widget.result.riskKey) {
      case 'high':
        return const Color(0xFFB3261E);
      case 'review':
        return satarkAmber;
      default:
        return const Color(0xFF51607A);
    }
  }

  Color get _onHeader => widget.result.riskKey == 'review' ? satarkNavy : Colors.white;

  IconData get _headerIcon {
    switch (widget.result.riskKey) {
      case 'high':
        return Icons.gpp_bad_outlined;
      case 'review':
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _speak() async {
    try {
      if (_speaking) {
        await _tts.stop();
        if (mounted) setState(() => _speaking = false);
        return;
      }
      final ai = widget.result.aiExplanation;
      final text = ai == null || ai.isEmpty ? widget.result.spokenSummary : '${widget.result.spokenSummary} $ai';
      await _tts.setLanguage(isHindi(_lang) ? 'hi-IN' : 'en-IN');
      await _tts.setSpeechRate(0.44);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      if (mounted) setState(() => _speaking = true);
      await _tts.speak(text);
    } catch (_) {
      _snack(tr(_lang, 'Speech output is unavailable for this language on this device.', 'इस फ़ोन पर इस भाषा में बोलकर सुनाना उपलब्ध नहीं है।'));
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({required String title, required String body, required String okLabel}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(_lang, 'Cancel', 'रद्द करें'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(okLabel)),
        ],
      ),
    );
    return ok == true;
  }

  /// Picks the trusted contact to use: the only one, or one chosen from a list.
  Future<Map<String, String>?> _pickContact() async {
    if (_contacts.isEmpty) {
      _snack(tr(_lang, 'Add a trusted contact in Settings first.', 'पहले सेटिंग्स में भरोसेमंद व्यक्ति जोड़ें।'));
      return null;
    }
    if (_contacts.length == 1) return _contacts.first;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr(_lang, 'Choose a trusted contact', 'किसे चुनना है?')),
        children: _contacts
            .map((contact) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, contact),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text((contact['name'] ?? '').isEmpty ? tr(_lang, 'Trusted contact', 'भरोसेमंद व्यक्ति') : contact['name']!),
                    subtitle: Text(contact['phone'] ?? ''),
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _displayName(Map<String, String> contact) {
    final name = (contact['name'] ?? '').trim();
    return name.isEmpty ? tr(_lang, 'your trusted contact', 'अपने भरोसेमंद व्यक्ति') : name;
  }

  Future<void> _callTrustedContact() async {
    final contact = await _pickContact();
    if (contact == null || !mounted) return;
    final phone = contact['phone'] ?? '';
    final name = _displayName(contact);
    final confirmed = await _confirm(
      title: tr(_lang, 'Call $name?', '$name को कॉल करें?'),
      body: tr(_lang, 'Satark will open your phone app with $phone. You can review the number before placing the call.', 'सतर्क $phone नंबर के साथ फ़ोन ऐप खोलेगा। कॉल करने से पहले नंबर जाँच सकते हैं।'),
      okLabel: tr(_lang, 'Open phone app', 'फ़ोन ऐप खोलें'),
    );
    if (!confirmed || !mounted) return;
    await _launch(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _messageOnWhatsApp() async {
    final contact = await _pickContact();
    if (contact == null || !mounted) return;
    final name = _displayName(contact);
    final confirmed = await _confirm(
      title: tr(_lang, 'Message $name on WhatsApp?', '$name को WhatsApp पर संदेश भेजें?'),
      body: tr(
        _lang,
        'WhatsApp will open with a short pre-written note. Your checked message and this result are NOT included, and nothing is sent until you press send.',
        'WhatsApp एक छोटे तैयार संदेश के साथ खुलेगा। आपका जाँचा हुआ संदेश और यह परिणाम उसमें शामिल नहीं हैं, और जब तक आप भेजें नहीं दबाएँगे कुछ नहीं जाएगा।',
      ),
      okLabel: tr(_lang, 'Open WhatsApp', 'WhatsApp खोलें'),
    );
    if (!confirmed || !mounted) return;
    final note = tr(_lang, 'I received a message that may be a scam. Can you help me check it?', 'मुझे एक संदेश मिला है जो धोखाधड़ी हो सकता है। क्या आप जाँचने में मेरी मदद कर सकते हैं?');
    final number = _whatsAppNumber(contact['phone'] ?? '');
    await _launch(Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(note)}'));
  }

  Future<void> _call1930() async {
    final confirmed = await _confirm(
      title: tr(_lang, 'Call the cyber crime helpline?', 'साइबर क्राइम हेल्पलाइन पर कॉल करें?'),
      body: tr(_lang, 'Satark will open your phone app with 1930, the national cyber crime helpline. Call it quickly if you have already paid or shared details.', 'सतर्क आपका फ़ोन ऐप 1930 (राष्ट्रीय साइबर क्राइम हेल्पलाइन) के साथ खोलेगा। अगर आप पैसे भेज चुके हैं या जानकारी दे चुके हैं तो जल्दी कॉल करें।'),
      okLabel: tr(_lang, 'Open phone app', 'फ़ोन ऐप खोलें'),
    );
    if (!confirmed || !mounted) return;
    await _launch(Uri(scheme: 'tel', path: '1930'));
  }

  Future<void> _launch(Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) _snack(tr(_lang, 'Could not open that app on this device.', 'इस फ़ोन पर वह ऐप नहीं खुल सका।'));
    } catch (_) {
      _snack(tr(_lang, 'Could not open that app on this device.', 'इस फ़ोन पर वह ऐप नहीं खुल सका।'));
    }
  }

  /// wa.me needs digits only, with the country code. Ten-digit numbers are treated as Indian.
  String _whatsAppNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) digits = '91$digits';
    return digits;
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final flagged = result.riskKey != 'low_indicators';
    final callLabel = _contacts.length == 1 && (_contacts.first['name'] ?? '').trim().isNotEmpty
        ? tr(_lang, 'Call ${_contacts.first['name']!.trim()}', '${_contacts.first['name']!.trim()} को कॉल करें')
        : tr(_lang, 'Call my trusted contact', 'भरोसेमंद व्यक्ति को कॉल करें');

    return Scaffold(
      backgroundColor: satarkPaper,
      appBar: AppBar(
        backgroundColor: _headerColor,
        foregroundColor: _onHeader,
        elevation: 0,
        title: Text(tr(_lang, 'Satark check', 'सतर्क जाँच')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              color: _headerColor,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_headerIcon, size: 56, color: _onHeader),
                  const SizedBox(height: 10),
                  Text(result.riskLabel, style: TextStyle(color: _onHeader, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Text(result.category, style: TextStyle(color: _onHeader, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(result.spokenSummary, style: TextStyle(color: _onHeader, fontSize: 17, height: 1.5)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _callTrustedContact,
                    icon: const Icon(Icons.call),
                    label: Text(callLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: satarkNavy,
                      minimumSize: const Size.fromHeight(64),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _speak,
                          icon: Icon(_speaking ? Icons.stop : Icons.volume_up_outlined),
                          label: Text(_speaking ? tr(_lang, 'Stop', 'रोकें') : tr(_lang, 'Hear advice', 'सलाह सुनें')),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: satarkNavy),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _messageOnWhatsApp,
                          icon: const Icon(Icons.chat_outlined),
                          label: Text(tr(_lang, 'WhatsApp', 'WhatsApp')),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: satarkNavy),
                        ),
                      ),
                    ],
                  ),
                  if (flagged) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _call1930,
                      icon: const Icon(Icons.local_police_outlined),
                      label: Text(tr(_lang, 'Report a scam: call 1930', 'धोखाधड़ी की शिकायत: 1930 पर कॉल करें')),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: const Color(0xFFB3261E), side: const BorderSide(color: Color(0xFFB3261E))),
                    ),
                  ],
                  if (result.aiExplanation != null && result.aiExplanation!.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: tr(_lang, 'AI explanation (on this phone)', 'AI की व्याख्या (इसी फ़ोन पर)'),
                      icon: Icons.auto_awesome_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.aiExplanation!, style: const TextStyle(fontSize: 15, height: 1.5)),
                          const SizedBox(height: 8),
                          Text(
                            tr(_lang, 'Written by a small AI model that runs on this phone. It can be wrong, so use it only as a second opinion.', 'यह इसी फ़ोन पर चलने वाले छोटे AI मॉडल ने लिखा है। यह गलत हो सकता है, इसलिए इसे केवल दूसरी राय मानें।'),
                            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF626A7F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: tr(
                      _lang,
                      result.riskKey == 'low_indicators' ? 'What the check found' : 'Why it was flagged',
                      result.riskKey == 'low_indicators' ? 'जाँच में क्या मिला' : 'चेतावनी क्यों मिली',
                    ),
                    icon: Icons.search,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (result.evidence.isNotEmpty) ...[
                          Text(tr(_lang, 'Phrases detected in the message', 'संदेश में मिले वाक्यांश'), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...result.evidence.map((phrase) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(color: const Color(0xFFFFF4D8), borderRadius: BorderRadius.circular(12)),
                                child: Text('“$phrase”', style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
                              )),
                        ],
                        ...result.warningSigns.map((reason) => Padding(
                              padding: const EdgeInsets.only(top: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 7, color: satarkTeal)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(reason, style: const TextStyle(fontSize: 15, height: 1.4))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: tr(_lang, 'What to do next', 'अब क्या करें'),
                    icon: Icons.checklist,
                    child: Column(
                      children: List.generate(
                        result.nextSteps.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(bottom: index == result.nextSteps.length - 1 ? 0 : 13),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: satarkTeal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                                child: Text('${index + 1}', style: const TextStyle(color: satarkTeal, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 11),
                              Expanded(child: Text(result.nextSteps[index], style: const TextStyle(fontSize: 15, height: 1.45))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: const Color(0xFFE5EFEF), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: satarkTeal),
                        const SizedBox(width: 10),
                        Expanded(child: Text(result.disclaimer, style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF48566A)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(tr(_lang, 'Check another message', 'दूसरा संदेश जाँचें')),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: satarkNavy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(icon, color: satarkTeal), const SizedBox(width: 9), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium))]),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
}
