import 'package:flutter/material.dart';

import '../ai/ai_engine.dart';
import '../app.dart';
import '../l10n.dart';
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
  List<Map<String, String>> _contacts = [];
  bool _aiEnabled = true;
  bool _aiInstalled = false;
  bool _aiBusy = false;
  int _aiPercent = 0;

  String get _lang => widget.language;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final values = await Future.wait([
      LocalStore.isHistoryEnabled(),
      LocalStore.getContacts(),
      LocalStore.isAiEnabled(),
    ]);
    final engine = AiRegistry.engine;
    final installed = engine == null ? false : await engine.isModelInstalled();
    if (!mounted) return;
    setState(() {
      _historyEnabled = values[0] as bool;
      _contacts = (values[1] as List<Map<String, String>>);
      _aiEnabled = values[2] as bool;
      _aiInstalled = installed;
      _loading = false;
    });
  }

  Future<void> _toggleHistory(bool enabled) async {
    await LocalStore.setHistoryEnabled(enabled);
    if (mounted) {
      setState(() => _historyEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enabled ? tr(_lang, 'Local history enabled.', 'इतिहास चालू हो गया।') : tr(_lang, 'History disabled and saved checks deleted.', 'इतिहास बंद हुआ और सहेजी जाँचें हटा दी गईं।')),
      ));
    }
  }

  Future<void> _toggleAi(bool enabled) async {
    await LocalStore.setAiEnabled(enabled);
    if (mounted) setState(() => _aiEnabled = enabled);
  }

  Future<void> _installAi() async {
    final engine = AiRegistry.engine;
    if (engine == null) return;
    if (!await engine.isOnWifi()) {
      if (!mounted) return;
      _snack(tr(_lang, 'Connect to Wi-Fi first. The model is about ${engine.sizeLabel}.', 'पहले Wi-Fi से जुड़ें। मॉडल लगभग ${engine.sizeLabel} का है।'));
      return;
    }
    setState(() {
      _aiBusy = true;
      _aiPercent = 0;
    });
    try {
      await engine.installModel(onProgress: (p) {
        if (mounted) setState(() => _aiPercent = p);
      });
      final ok = await engine.isModelInstalled();
      if (mounted) setState(() => _aiInstalled = ok);
    } catch (_) {
      _snack(tr(_lang, 'Download failed. Please try again on Wi-Fi.', 'डाउनलोड नहीं हो सका। Wi-Fi पर फिर कोशिश करें।'));
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _removeAi() async {
    final engine = AiRegistry.engine;
    if (engine == null) return;
    await engine.removeModel();
    final ok = await engine.isModelInstalled();
    if (mounted) setState(() => _aiInstalled = ok);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _aiCard() {
    final engine = AiRegistry.engine;
    if (engine == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.psychology_outlined, color: satarkTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(_lang, 'On-device AI helper: not included in this build. Satark uses its transparent rule checker only. See optional_ai/README.md to add it.', 'फ़ोन पर चलने वाला AI सहायक: इस बिल्ड में शामिल नहीं है। सतर्क केवल अपने पारदर्शी नियम-जाँचक का उपयोग करता है।'),
                style: const TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.45),
              ),
            ),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.psychology_outlined, color: satarkTeal),
            const SizedBox(width: 10),
            Expanded(child: Text(tr(_lang, 'On-device AI helper', 'फ़ोन पर AI सहायक'), style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 8),
          Text(
            tr(_lang, '${engine.displayName} (${engine.sizeLabel}) runs on this phone, never online. It can only raise a warning, never lower it, and explains in plain words.', '${engine.displayName} (${engine.sizeLabel}) इसी फ़ोन पर चलता है, ऑनलाइन नहीं। यह चेतावनी बढ़ा सकता है, घटा नहीं सकता, और सरल शब्दों में समझाता है।'),
            style: const TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 10),
          if (_aiBusy) ...[
            LinearProgressIndicator(value: _aiPercent > 0 ? _aiPercent / 100 : null),
            const SizedBox(height: 6),
            Text(tr(_lang, 'Downloading… $_aiPercent%', 'डाउनलोड हो रहा है… $_aiPercent%')),
          ] else if (!_aiInstalled)
            ElevatedButton.icon(onPressed: _installAi, icon: const Icon(Icons.download), label: Text(tr(_lang, 'Download model (Wi-Fi)', 'मॉडल डाउनलोड करें (Wi-Fi)')))
          else ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _aiEnabled,
              onChanged: _toggleAi,
              title: Text(tr(_lang, 'Use AI helper', 'AI सहायक इस्तेमाल करें')),
            ),
            TextButton.icon(onPressed: _removeAi, icon: const Icon(Icons.delete_outline), label: Text(tr(_lang, 'Remove model from phone', 'मॉडल फ़ोन से हटाएँ'))),
          ],
        ]),
      ),
    );
  }

  Future<void> _deleteAllHistory() async {
    await LocalStore.clearHistory();
    _snack(tr(_lang, 'All saved checks deleted.', 'सभी सहेजी गई जाँचें हटा दी गईं।'));
  }

  Future<void> _saveContact() async {
    final phone = _contactPhone.text.trim();
    if (phone.isEmpty || !RegExp(r'^[+0-9()\-\s]{7,20}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(_lang, 'Enter a valid phone number, including country code if needed.', 'सही फ़ोन नंबर डालें, ज़रूरत हो तो देश कोड सहित।'))));
      return;
    }
    await LocalStore.saveContact(name: _contactName.text, phone: phone);
    await _loadSettings();
    _contactName.clear();
    _contactPhone.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(_lang, 'Trusted contact saved on this device.', 'भरोसेमंद संपर्क इसी फ़ोन पर सहेजा गया।'))));
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
      appBar: AppBar(title: Text(tr(_lang, 'Settings', 'सेटिंग्स'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                Text(tr(_lang, 'Personalise Satark', 'सतर्क अपने हिसाब से बनाएँ'), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(tr(_lang, 'Set a language and save trusted contacts for moments when a message feels suspicious.', 'भाषा चुनें और भरोसेमंद संपर्क सहेजें, ताकि संदिग्ध संदेश के समय काम आएँ।'), style: TextStyle(color: Color(0xFF626A7F), height: 1.45)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr(_lang, 'Result language', 'नतीजों की भाषा'), style: Theme.of(context).textTheme.titleMedium),
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
                      Row(children: [const Icon(Icons.family_restroom, color: satarkTeal), const SizedBox(width: 10), Expanded(child: Text(tr(_lang, 'Trusted contacts', 'भरोसेमंद संपर्क'), style: Theme.of(context).textTheme.titleMedium))]),
                      const SizedBox(height: 8),
                      Text(tr(_lang, 'These people are never alerted automatically. Satark only opens the phone or WhatsApp after you tap a button and confirm.', 'इन लोगों को अपने-आप कभी सूचना नहीं जाती। बटन दबाने और पुष्टि करने के बाद ही सतर्क फ़ोन या WhatsApp खोलता है।'), style: TextStyle(color: Color(0xFF626A7F), fontSize: 13, height: 1.45)),
                      if (_contacts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._contacts.map((contact) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text((contact['name'] ?? '').isEmpty ? tr(_lang, 'Trusted contact', 'भरोसेमंद संपर्क') : contact['name']!),
                          subtitle: Text(contact['phone'] ?? ''),
                          trailing: IconButton(
                            tooltip: tr(_lang, 'Remove contact', 'संपर्क हटाएँ'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await LocalStore.deleteContact(contact['phone'] ?? '');
                              await _loadSettings();
                            },
                          ),
                        )),
                        const Divider(),
                      ],
                      const SizedBox(height: 8),
                      TextField(controller: _contactName, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: tr(_lang, 'New contact name', 'नए संपर्क का नाम'), hintText: tr(_lang, 'e.g. Son, daughter, friend', 'जैसे बेटा, बेटी, दोस्त'))),
                      const SizedBox(height: 11),
                      TextField(controller: _contactPhone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: tr(_lang, 'Phone number', 'फ़ोन नंबर'), hintText: '+91 98765 43210')),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(onPressed: _saveContact, icon: const Icon(Icons.person_add_alt_1), label: Text(tr(_lang, 'Add / update trusted contact', 'भरोसेमंद संपर्क जोड़ें/बदलें'))),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile.adaptive(
                    value: _historyEnabled,
                    onChanged: _toggleHistory,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    title: Text(tr(_lang, 'Optional local history', 'वैकल्पिक स्थानीय इतिहास'), style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(tr(_lang, 'Off by default. When enabled, recent checks are stored in the secure-storage area on this device. Turning it off deletes saved checks.', 'शुरू में बंद। चालू होने पर हाल की जाँचें इस फ़ोन के सुरक्षित स्टोरेज में रखी जाती हैं। बंद करने पर सहेजी जाँचें हट जाती हैं।'), style: TextStyle(height: 1.45)),
                    ),
                    secondary: const Icon(Icons.lock_outline, color: satarkTeal),
                  ),
                ),
                if (_historyEnabled) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _deleteAllHistory, icon: const Icon(Icons.delete_sweep_outlined), label: Text(tr(_lang, 'Delete all saved checks now', 'सभी सहेजी जाँचें अभी हटाएँ')))),
                const SizedBox(height: 14),
                _aiCard(),
                const SizedBox(height: 20),
                Text(tr(_lang, 'About this MVP', 'इस MVP के बारे में'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _InfoRow(title: tr(_lang, 'Local rule checks', 'स्थानीय नियम-जाँच'), text: tr(_lang, 'The checker looks for known scam patterns on this phone. It can miss new wording or flag genuine messages.', 'जाँचक इसी फ़ोन पर जाने-पहचाने ठगी के पैटर्न खोजता है। यह नए शब्द चूक सकता है या असली संदेश को भी चिह्नित कर सकता है।')),
                _InfoRow(title: tr(_lang, 'No automatic alerts', 'कोई अपने-आप अलर्ट नहीं'), text: tr(_lang, 'Satark never sends your message or alerts family contacts automatically.', 'सतर्क आपका संदेश कभी नहीं भेजता और परिवार को अपने-आप सूचना नहीं देता।')),
                _InfoRow(title: tr(_lang, 'Not a guarantee', 'गारंटी नहीं'), text: tr(_lang, 'A low-warning result does not mean a message is safe. Verify important requests independently.', 'कम संकेत का मतलब यह नहीं कि संदेश सुरक्षित है। ज़रूरी अनुरोध अलग से जाँचें।')),
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
