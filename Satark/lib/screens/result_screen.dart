import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
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

  Color get _riskColor {
    switch (widget.result.riskKey) {
      case 'high':
        return const Color(0xFFB3261E);
      case 'review':
        return const Color(0xFF9A5B00);
      default:
        return satarkTeal;
    }
  }

  Future<void> _speak() async {
    try {
      if (_speaking) {
        await _tts.stop();
        if (mounted) setState(() => _speaking = false);
        return;
      }
      await _tts.setLanguage(widget.result.language == 'हिन्दी' ? 'hi-IN' : 'en-IN');
      await _tts.setSpeechRate(0.44);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      if (mounted) setState(() => _speaking = true);
      await _tts.speak(widget.result.spokenSummary);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech output is unavailable for this language on this device.')));
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _callTrustedContact() async {
    final phone = await LocalStore.getContactPhone();
    final name = await LocalStore.getContactName();
    if (!mounted) return;
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.result.language == 'हिन्दी' ? 'पहले Settings में भरोसेमंद व्यक्ति जोड़ें।' : 'Add a trusted contact in Settings first.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.result.language == 'हिन्दी'
            ? '${name.isEmpty ? 'अपने भरोसेमंद व्यक्ति' : name} को कॉल करें?'
            : 'Call ${name.isEmpty ? 'your trusted contact' : name}?'),
        content: Text(widget.result.language == 'हिन्दी'
            ? 'सतर्क $phone नंबर के साथ फ़ोन ऐप खोलेगा। कॉल करने से पहले नंबर जाँच सकते हैं।'
            : 'Satark will open your phone app with $phone. You can review the number before placing the call.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(widget.result.language == 'हिन्दी' ? 'रद्द करें' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(widget.result.language == 'हिन्दी' ? 'फ़ोन ऐप खोलें' : 'Open phone app')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final launched = await launchUrl(Uri(scheme: 'tel', path: phone), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the phone app on this device.')));
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _tts.awaitSpeakCompletion(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isHindi = result.language == 'हिन्दी';
    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'सतर्क जाँच' : 'Satark check'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE3E3DD))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isHindi ? 'परिणाम' : 'RESULT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11, color: Color(0xFF72798B))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: _riskColor.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                    child: Text(result.riskLabel, style: TextStyle(color: _riskColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                  ),
                  const SizedBox(height: 12),
                  Text(result.category, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(result.spokenSummary, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _speak,
                    icon: Icon(_speaking ? Icons.stop : Icons.volume_up_outlined),
                    label: Text(_speaking ? (isHindi ? 'पढ़ना रोकें' : 'Stop reading') : (isHindi ? 'सलाह सुनें' : 'Hear this advice')),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: satarkNavy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: isHindi
                  ? (result.riskKey == 'low_indicators' ? 'जाँच में क्या मिला' : 'चेतावनी क्यों मिली')
                  : (result.riskKey == 'low_indicators' ? 'What the check found' : 'Why it was flagged'),
              icon: Icons.search,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.evidence.isNotEmpty) ...[
                    Text(isHindi ? 'संदेश में मिले वाक्यांश' : 'Phrases detected in the message', style: TextStyle(fontWeight: FontWeight.w700)),
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
                            const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.circle, size: 7, color: satarkTeal)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(reason, style: const TextStyle(fontSize: 14, height: 1.4))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: isHindi ? 'अब क्या करें' : 'What to do next',
              icon: Icons.checklist,
              child: Column(
                children: List.generate(result.nextSteps.length, (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == result.nextSteps.length - 1 ? 0 : 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: satarkTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                        child: Text('${index + 1}', style: const TextStyle(color: satarkTeal, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: Text(result.nextSteps[index], style: const TextStyle(fontSize: 14, height: 1.45))),
                    ],
                  ),
                )),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _callTrustedContact,
              icon: const Icon(Icons.call_outlined),
              label: Text(isHindi ? 'भरोसेमंद व्यक्ति को कॉल करें' : 'Call my trusted contact'),
              style: ElevatedButton.styleFrom(backgroundColor: satarkNavy),
            ),
            const SizedBox(height: 13),
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
              label: Text(isHindi ? 'दूसरा संदेश जाँचें' : 'Check another message'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: satarkNavy),
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
