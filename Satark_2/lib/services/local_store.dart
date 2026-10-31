import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _historyEnabledKey = 'satark.history.enabled';
  static const String _historyEntriesKey = 'satark.history.entries';
  static const String _contactNameKey = 'satark.contact.name'; // legacy migration
  static const String _contactPhoneKey = 'satark.contact.phone'; // legacy migration
  static const String _contactsKey = 'satark.contacts';
  static const String _languageKey = 'satark.language';
  static const String _onboardingCompletedKey = 'satark.onboarding.completed';
  static const String _aiEnabledKey = 'satark.ai.enabled';

  static Future<bool> isOnboardingComplete() async =>
      (await _storage.read(key: _onboardingCompletedKey)) == 'true';

  static Future<void> markOnboardingComplete() =>
      _storage.write(key: _onboardingCompletedKey, value: 'true');

  static Future<String> getLanguage() async =>
      await _storage.read(key: _languageKey) ?? 'English';

  static Future<void> setLanguage(String language) =>
      _storage.write(key: _languageKey, value: language);

  /// Whether the optional on-device AI explanation is switched on (default: on, but it
  /// only does anything when the AI module is enabled and its model is installed).
  static Future<bool> isAiEnabled() async =>
      (await _storage.read(key: _aiEnabledKey)) != 'false';

  static Future<void> setAiEnabled(bool enabled) =>
      _storage.write(key: _aiEnabledKey, value: enabled.toString());

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

  /// Removes one saved check (position in the list returned by [getHistory]).
  static Future<void> deleteHistoryEntry(int index) async {
    final entries = await getHistory();
    if (index < 0 || index >= entries.length) return;
    entries.removeAt(index);
    await _storage.write(key: _historyEntriesKey, value: jsonEncode(entries));
  }

  static Future<void> clearHistory() => _storage.delete(key: _historyEntriesKey);

  static Future<List<Map<String, String>>> getContacts() async {
    final raw = await _storage.read(key: _contactsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.whereType<Map<String, dynamic>>().map((item) => {
          'id': (item['id'] ?? item['phone'] ?? '').toString(),
          'name': (item['name'] ?? '').toString(),
          'phone': (item['phone'] ?? '').toString(),
        }).where((item) => item['phone']!.isNotEmpty).toList();
      } catch (_) {
        return [];
      }
    }
    // Migrate the previous single-contact format without losing the saved contact.
    final oldName = (await _storage.read(key: _contactNameKey) ?? '').trim();
    final oldPhone = (await _storage.read(key: _contactPhoneKey) ?? '').trim();
    if (oldPhone.isNotEmpty) {
      final migrated = [{'id': oldPhone, 'name': oldName, 'phone': oldPhone}];
      await _storage.write(key: _contactsKey, value: jsonEncode(migrated));
      return migrated;
    }
    return [];
  }

  static Future<void> saveContact({required String name, required String phone}) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) return;
    final contacts = await getContacts();
    final index = contacts.indexWhere((contact) => contact['phone'] == cleanPhone);
    final entry = {'id': cleanPhone, 'name': cleanName, 'phone': cleanPhone};
    if (index >= 0) {
      contacts[index] = entry;
    } else {
      contacts.add(entry);
    }
    await _storage.write(key: _contactsKey, value: jsonEncode(contacts));
    // Keep legacy values in sync for old builds/flows during migration.
    await _storage.write(key: _contactNameKey, value: cleanName);
    await _storage.write(key: _contactPhoneKey, value: cleanPhone);
  }

  static Future<void> deleteContact(String phone) async {
    final contacts = await getContacts();
    contacts.removeWhere((contact) => contact['phone'] == phone);
    await _storage.write(key: _contactsKey, value: jsonEncode(contacts));
    await _storage.write(key: _contactNameKey, value: contacts.isEmpty ? '' : contacts.first['name'] ?? '');
    await _storage.write(key: _contactPhoneKey, value: contacts.isEmpty ? '' : contacts.first['phone'] ?? '');
  }

  static Future<String> getContactName() async {
    final contacts = await getContacts();
    return contacts.isEmpty ? '' : contacts.first['name'] ?? '';
  }

  static Future<String> getContactPhone() async {
    final contacts = await getContacts();
    return contacts.isEmpty ? '' : contacts.first['phone'] ?? '';
  }
}
