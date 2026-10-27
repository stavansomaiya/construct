import 'package:flutter/material.dart';

import '../app.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number, or leave it blank and add it later.')));
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
                  const Text('Pause. Check. Protect.', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  const Text('A calm second opinion before you pay, click, or share private information.', style: TextStyle(color: Color(0xFFE1E6F3), fontSize: 16, height: 1.5)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: const Color(0xFF233052), borderRadius: BorderRadius.circular(15)),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.lock_outline, color: satarkAmber),
                      SizedBox(width: 10),
                      Expanded(child: Text('This first build checks known warning patterns locally. It does not send your message to a cloud AI service. Results are not guarantees.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Text('Set up Satark', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              const Text('You can change these choices later in Settings.', style: TextStyle(color: Color(0xFF626A7F))),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Preferred result language', style: Theme.of(context).textTheme.titleMedium),
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
                    Text('Trusted contact (optional)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    const Text('Satark will never alert this person automatically. The result screen can open the phone app after you confirm.', style: TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.4)),
                    const SizedBox(height: 13),
                    TextField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Contact name')),
                    const SizedBox(height: 10),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: '+91 98765 43210')),
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
                  title: const Text('Save checks on this device', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Optional and off by default. Stored in secure device storage. You can delete history at any time.', style: TextStyle(height: 1.4)),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _saving ? null : _start,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.arrow_forward),
                label: const Text('Start using Satark'),
              ),
              const SizedBox(height: 12),
              const Text('Satark is a decision aid, not proof that a message is genuine. Always verify urgent requests through an independent official channel.', style: TextStyle(color: Color(0xFF757C8E), fontSize: 12, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}
