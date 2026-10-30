import 'package:shared_preferences/shared_preferences.dart';

/// Helper service for non-sensitive local device preferences.
/// (Used only for local theme, notification audio toggles, and UI preferences).
class StorageService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  Future<void> saveVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrationEnabled, enabled);
  }

  Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVibrationEnabled) ?? true;
  }

  Future<void> setHasSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, seen);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
