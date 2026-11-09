import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function(String language, String contactName, String contactPhone, bool historyEnabled) onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _language = 'English';
  bool _historyEnabled = false;
  bool _saving = false;

  Future<void> _start() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^[+0-9()\-\s]{7,20}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(_language, 'Enter a valid phone number, or leave it blank and add it later.', 'सही फ़ोन नंबर डालें, या खाली छोड़कर बाद में जोड़ें।'))));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onComplete(_language, _nameController.text.trim(), phone, _historyEnabled);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: satarkPaper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: satarkNavy, borderRadius: BorderRadius.circular(28)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    CircleAvatar(radius: 23, backgroundColor: satarkTeal, child: Text('S', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))),
                    SizedBox(width: 12),
                    Text('Satark', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 25),
                  Text(tr(_language, 'Pause. Check. Protect.', 'रुकें। जाँचें। सुरक्षित रहें।'), style: TextStyle(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(tr(_language, 'A calm second opinion before you pay, click, or share private information.', 'पैसे भेजने, लिंक खोलने या निजी जानकारी देने से पहले एक शांत दूसरी राय।'), style: TextStyle(color: Color(0xFFE1E6F3), fontSize: 16, height: 1.5)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: const Color(0xFF233052), borderRadius: BorderRadius.circular(15)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.lock_outline, color: satarkAmber),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tr(_language, 'Satark checks known warning patterns on this phone. Your message is never sent to a cloud service. Results are not guarantees.', 'सतर्क जाने-पहचाने ख़तरे के संकेत इसी फ़ोन पर जाँचता है। आपका संदेश किसी क्लाउड सेवा को नहीं भेजा जाता। नतीजे गारंटी नहीं हैं।'), style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Text(tr(_language, 'Set up Satark', 'सतर्क सेट करें'), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(tr(_language, 'You can change these choices later in Settings.', 'ये चुनाव बाद में सेटिंग्स में बदले जा सकते हैं।'), style: TextStyle(color: Color(0xFF626A7F))),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr(_language, 'Preferred result language', 'नतीजों की पसंदीदा भाषा'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'English', label: Text('English'), icon: Icon(Icons.language)),
                        ButtonSegment(value: 'हिन्दी', label: Text('हिन्दी'), icon: Icon(Icons.translate)),
                      ],
                      selected: {_language},
                      onSelectionChanged: (value) => setState(() => _language = value.first),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr(_language, 'Trusted contact (optional)', 'भरोसेमंद संपर्क (वैकल्पिक)'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(tr(_language, 'Satark will never alert this person automatically. The result screen can open the phone app after you confirm.', 'सतर्क इस व्यक्ति को अपने-आप कभी सूचना नहीं देगा। आपकी पुष्टि के बाद नतीजे की स्क्रीन फ़ोन ऐप खोल सकती है।'), style: TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.4)),
                    const SizedBox(height: 13),
                    TextField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: tr(_language, 'Contact name', 'संपर्क का नाम'))),
                    const SizedBox(height: 10),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: tr(_language, 'Phone number', 'फ़ोन नंबर'), hintText: '+91 98765 43210')),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile.adaptive(
                  value: _historyEnabled,
                  onChanged: (value) => setState(() => _historyEnabled = value),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  secondary: const Icon(Icons.lock_outline, color: satarkTeal),
                  title: Text(tr(_language, 'Save checks on this device', 'जाँचें इसी फ़ोन पर सहेजें'), style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(kIsWeb
                      ? tr(_language, 'Optional and off by default. Saved only in this browser. Avoid sensitive information on shared devices; delete history at any time.', 'वैकल्पिक और शुरू में बंद। केवल इसी ब्राउज़र में सहेजा जाता है। साझा डिवाइस पर संवेदनशील जानकारी न डालें; इतिहास कभी भी हटाएँ।')
                      : tr(_language, 'Optional and off by default. Stored in secure device storage. You can delete history at any time.', 'वैकल्पिक और शुरू में बंद। सुरक्षित स्टोरेज में रखा जाता है। इतिहास कभी भी हटा सकते हैं।'), style: TextStyle(height: 1.4)),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _saving ? null : _start,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.arrow_forward),
                label: Text(tr(_language, 'Start using Satark', 'सतर्क इस्तेमाल करें')),
              ),
              const SizedBox(height: 12),
              Text(tr(_language, 'Satark is a decision aid, not proof that a message is genuine. Always verify urgent requests through an independent official channel.', 'सतर्क निर्णय में मदद करता है, यह संदेश के असली होने का प्रमाण नहीं है। जल्दबाज़ी वाले अनुरोध हमेशा किसी आधिकारिक माध्यम से अलग से जाँचें।'), style: TextStyle(color: Color(0xFF757C8E), fontSize: 12, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}
