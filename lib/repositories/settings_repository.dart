import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

/// Persists [AppSettings] on the device.
class SettingsRepository {
  static const _key = 'app_settings_v1';

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    _settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AppSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
