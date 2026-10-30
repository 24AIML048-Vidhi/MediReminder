import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// Provider managing application theme, appearance, and audio/vibration toggles.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;

  ThemeMode _themeMode = ThemeMode.system;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoaded = false;

  ThemeProvider({StorageService? storageService})
    : _storageService = storageService ?? StorageService() {
    _loadPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isLoaded => _isLoaded;

  Future<void> _loadPreferences() async {
    final modeString = await _storageService.getThemeMode();
    _themeMode = _parseThemeMode(modeString);
    _soundEnabled = await _storageService.getSoundEnabled();
    _vibrationEnabled = await _storageService.getVibrationEnabled();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    await _storageService.saveThemeMode(modeString);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    await _storageService.saveSoundEnabled(enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();
    await _storageService.saveVibrationEnabled(enabled);
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
