import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _historyEnabledKey = 'satark.history.enabled';
  static const String _historyEntriesKey = 'satark.history.entries';
  static const String _contactNameKey = 'satark.contact.name';
  static const String _contactPhoneKey = 'satark.contact.phone';
  static const String _languageKey = 'satark.language';
  static const String _onboardingCompletedKey = 'satark.onboarding.completed';

  static Future<bool> isOnboardingComplete() async =>
      (await _storage.read(key: _onboardingCompletedKey)) == 'true';

  static Future<void> markOnboardingComplete() =>
      _storage.write(key: _onboardingCompletedKey, value: 'true');

  static Future<String> getLanguage() async =>
      await _storage.read(key: _languageKey) ?? 'English';

  static Future<void> setLanguage(String language) =>
      _storage.write(key: _languageKey, value: language);

  static Future<bool> isHistoryEnabled() async =>
      (await _storage.read(key: _historyEnabledKey)) == 'true';

  static Future<void> setHistoryEnabled(bool enabled) async {
    await _storage.write(key: _historyEnabledKey, value: enabled.toString());
    if (!enabled) await _storage.delete(key: _historyEntriesKey);
  }

  static Future<void> saveHistory(Map<String, dynamic> result) async {
    if (!await isHistoryEnabled()) return;
    final entries = await getHistory();
    entries.insert(0, {
      'savedAt': DateTime.now().toIso8601String(),
      'result': result,
    });
    final limited = entries.take(50).toList();
    await _storage.write(key: _historyEntriesKey, value: jsonEncode(limited));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final raw = await _storage.read(key: _historyEntriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: true);
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearHistory() => _storage.delete(key: _historyEntriesKey);

  static Future<void> saveContact({required String name, required String phone}) async {
    await _storage.write(key: _contactNameKey, value: name.trim());
    await _storage.write(key: _contactPhoneKey, value: phone.trim());
  }

  static Future<String> getContactName() async =>
      await _storage.read(key: _contactNameKey) ?? '';

  static Future<String> getContactPhone() async =>
      await _storage.read(key: _contactPhoneKey) ?? '';
}
