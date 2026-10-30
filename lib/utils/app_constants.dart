/// Application-wide constants for MediReminder.
class AppConstants {
  static const String appName = 'MediReminder';
  static const String appTagline = 'Smart Medicine & Health Reminder';
  static const String projectScope =
      'Mobile Application Development (MAD) Project';

  // SQLite Tables
  static const String tableUsers = 'users';
  static const String tableProfiles = 'user_profiles';
  static const String tableMedicines = 'medicines';
  static const String tableDoseLogs = 'dose_logs';
  static const String tableHealthRecords = 'health_records';
  static const String tableSettings = 'user_settings';

  // Medicine Forms
  static const List<String> medicineForms = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Inhaler',
    'Topical',
    'Other',
  ];

  // Dosage Units
  static const List<String> dosageUnits = [
    'mg',
    'g',
    'ml',
    'tablet(s)',
    'capsule(s)',
    'drop(s)',
    'puff(s)',
    'patch',
    'unit(s)',
  ];

  // Frequency Options
  static const String freqOnceDaily = 'once_daily';
  static const String freqTwiceDaily = 'twice_daily';
  static const String freqThreeDaily = 'three_times_daily';
  static const String freqCustom = 'custom';

  static const Map<String, String> frequencyLabels = {
    freqOnceDaily: 'Once daily',
    freqTwiceDaily: 'Twice daily',
    freqThreeDaily: '3 times daily',
    freqCustom: 'Custom schedule',
  };

  // Dose Log Statuses
  static const String statusTaken = 'taken';
  static const String statusSkipped = 'skipped';
  static const String statusMissed = 'missed';
  static const String statusPending = 'pending';

  // Blood Glucose Units
  static const String glucoseMgDl = 'mg/dL';
  static const String glucoseMmolL = 'mmol/L';

  // Notification Channel
  static const String notificationChannelId = 'medi_reminder_high_importance';
  static const String notificationChannelName = 'Medicine Reminders';
  static const String notificationChannelDesc =
      'High priority reminders for scheduled medication doses';
}
