import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettings {
  static const String defaultApiUrl = 'https://stepup.racknerd.chrispys.top';
  static const String defaultHealthSourceName = 'com.google.android.apps.fitness';

  static const String _apiUrlKey = 'api_url_override';
  static const String _healthSourceNameKey = 'health_source_name_override';
  static const String _lastHistorySyncMonthKey = 'last_history_sync_month';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  static Future<String> getApiUrl() async {
    final value = (await _storage.read(key: _apiUrlKey))?.trim();
    return value == null || value.isEmpty ? defaultApiUrl : value;
  }

  static Future<String> getHealthSourceName() async {
    final value = (await _storage.read(key: _healthSourceNameKey))?.trim();
    return value == null || value.isEmpty ? defaultHealthSourceName : value;
  }

  static Future<void> setApiUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == defaultApiUrl) {
      await _storage.delete(key: _apiUrlKey);
      return;
    }

    await _storage.write(key: _apiUrlKey, value: trimmed);
  }

  static Future<void> setHealthSourceName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == defaultHealthSourceName) {
      await _storage.delete(key: _healthSourceNameKey);
      return;
    }

    await _storage.write(key: _healthSourceNameKey, value: trimmed);
  }

  static Future<void> resetOverrides() async {
    await _storage.delete(key: _apiUrlKey);
    await _storage.delete(key: _healthSourceNameKey);
  }

  /// Returns the stored sync month string (e.g. "2026-08"), or null if never synced.
  static Future<String?> getLastHistorySyncMonth() async {
    return await _storage.read(key: _lastHistorySyncMonthKey);
  }

  /// Stores the given month string (e.g. "2026-08") as the last synced month.
  static Future<void> setLastHistorySyncMonth(String yearMonth) async {
    await _storage.write(key: _lastHistorySyncMonthKey, value: yearMonth);
  }
}
