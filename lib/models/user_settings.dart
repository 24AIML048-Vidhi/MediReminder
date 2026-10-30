/// User preference settings stored under users/{uid}/settings/main and SharedPreferences.
class UserSettings {
  final String userId;
  final bool remindersEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String themeMode; // 'system', 'light', 'dark'
  final String dateFormat;

  const UserSettings({
    required this.userId,
    this.remindersEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.themeMode = 'system',
    this.dateFormat = 'MMM dd, yyyy',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'remindersEnabled': remindersEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'themeMode': themeMode,
      'dateFormat': dateFormat,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map, String uid) {
    bool parseBool(dynamic val, bool def) {
      if (val is int) return val == 1;
      if (val is bool) return val;
      return def;
    }

    return UserSettings(
      userId: uid.isNotEmpty ? uid : (map['userId'] as String? ?? ''),
      remindersEnabled: parseBool(map['remindersEnabled'], true),
      soundEnabled: parseBool(map['soundEnabled'], true),
      vibrationEnabled: parseBool(map['vibrationEnabled'], true),
      themeMode: map['themeMode'] as String? ?? 'system',
      dateFormat: map['dateFormat'] as String? ?? 'MMM dd, yyyy',
    );
  }

  UserSettings copyWith({
    String? userId,
    bool? remindersEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? themeMode,
    String? dateFormat,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      themeMode: themeMode ?? this.themeMode,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}
