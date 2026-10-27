import 'package:flutter/material.dart';

import '../app.dart';
import '../services/local_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.language, required this.onLanguageChanged});

  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _contactName = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  bool _historyEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final values = await Future.wait([
      LocalStore.isHistoryEnabled(),
      LocalStore.getContactName(),
      LocalStore.getContactPhone(),
    ]);
    if (!mounted) return;
    setState(() {
      _historyEnabled = values[0] as bool;
      _contactName.text = values[1] as String;
      _contactPhone.text = values[2] as String;
      _loading = false;
    });
  }

  Future<void> _toggleHistory(bool enabled) async {
    await LocalStore.setHistoryEnabled(enabled);
    if (mounted) {
      setState(() => _historyEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enabled ? 'Local history enabled.' : 'History disabled and saved checks deleted.'),
      ));
    }
  }

  Future<void> _saveContact() async {
    final phone = _contactPhone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^[+0-9()\-\s]{7,20}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number, including country code if needed.')));
      return;
    }
    await LocalStore.saveContact(name: _contactName.text, phone: phone);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trusted contact saved on this device.')));
  }

  @override
  void dispose() {
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                Text('Personalise Satark', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                const Text('Set a language and save one trusted contact for moments when a message feels suspicious.', style: TextStyle(color: Color(0xFF626A7F), height: 1.45)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Result language', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'English', label: Text('English'), icon: Icon(Icons.language)),
                          ButtonSegment(value: 'हिन्दी', label: Text('हिन्दी'), icon: Icon(Icons.translate)),
                        ],
                        selected: {widget.language},
                        onSelectionChanged: (value) {
                          if (value.isNotEmpty) widget.onLanguageChanged(value.first);
                        },
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.family_restroom, color: satarkTeal), const SizedBox(width: 10), Expanded(child: Text('Trusted contact', style: Theme.of(context).textTheme.titleMedium))]),
                      const SizedBox(height: 8),
                      const Text('This person is not alerted automatically. Satark only opens the phone app after you tap the call button and confirm.', style: TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.45)),
                      const SizedBox(height: 14),
                      TextField(controller: _contactName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Contact name', hintText: 'e.g. Son, daughter, friend')),
                      const SizedBox(height: 11),
                      TextField(controller: _contactPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: '+91 98765 43210')),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(onPressed: _saveContact, icon: const Icon(Icons.save_outlined), label: const Text('Save trusted contact')),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile.adaptive(
                    value: _historyEnabled,
                    onChanged: _toggleHistory,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    title: const Text('Optional local history', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text('Off by default. When enabled, recent checks are stored in the platform secure-storage area on this device. Turning it off deletes saved checks.', style: TextStyle(height: 1.45)),
                    ),
                    secondary: const Icon(Icons.lock_outline, color: satarkTeal),
                  ),
                ),
                const SizedBox(height: 20),
                Text('About this MVP', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                const _InfoRow(title: 'Local rule checks', text: 'The current checker looks for known scam patterns. It is not a trained AI model and can miss new wording or flag legitimate messages.'),
                const _InfoRow(title: 'No automatic alerts', text: 'Satark never sends your message or alerts family contacts automatically.'),
                const _InfoRow(title: 'Not a guarantee', text: 'A low-warning result does not mean a message is safe. Verify important requests independently.'),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.check_circle_outline, color: satarkTeal, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(text, style: const TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.45))])),
        ]),
      );
}
