import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';

/// Schedule slot item combining medicine details with its scheduled time and logged status
class ScheduledDoseItem {
  final Medicine medicine;
  final int timeIndex;
  final DateTime scheduledDateTime;
  final DoseLog? log;

  const ScheduledDoseItem({
    required this.medicine,
    required this.timeIndex,
    required this.scheduledDateTime,
    this.log,
  });

  /// Deterministic unique log ID for this specific scheduled dose
  String get deterministicLogId {
    return '${medicine.id}_${scheduledDateTime.year}_${scheduledDateTime.month}_${scheduledDateTime.day}_$timeIndex';
  }

  bool get isLogged => log != null;
  bool get isTaken => log?.status == 'taken';
  bool get isSkipped => log?.status == 'skipped';
  bool get isMissed =>
      log?.status == 'missed' ||
      (log == null && scheduledDateTime.isBefore(DateTime.now()));
  bool get isPending =>
      log == null && scheduledDateTime.isAfter(DateTime.now());
}

/// Provider managing dose history, dose logging, and adherence metrics
class DoseLogProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<DoseLog> _logs = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<DoseLog>>? _logsSubscription;
  String? _currentUserId;

  DoseLogProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  List<DoseLog> get allLogs => _logs;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Binds provider to the user's SQLite dose logs stream
  void bindUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _logsSubscription?.cancel();

    if (userId == null) {
      _logs = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _logsSubscription = _databaseService
        .doseLogsStream(userId)
        .listen(
          (logs) {
            _logs = logs;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _errorMessage = 'Failed to load dose logs: $e';
            notifyListeners();
          },
        );
  }

  /// Finds existing dose log for a specific medicine at a specific date and time slot
  DoseLog? getLogFor(
    String medicineId,
    DateTime scheduledDateTime,
    int timeIndex,
  ) {
    final logId =
        '${medicineId}_${scheduledDateTime.year}_${scheduledDateTime.month}_${scheduledDateTime.day}_$timeIndex';
    try {
      return _logs.firstWhere((log) => log.id == logId);
    } catch (_) {
      return null;
    }
  }

  /// Computes all scheduled dose items for [date] given the list of medicines
  List<ScheduledDoseItem> getDoseItemsForDate(
    DateTime date,
    List<Medicine> medicines,
  ) {
    final List<ScheduledDoseItem> items = [];
    final dateOnly = DateTime(date.year, date.month, date.day);

    for (final med in medicines) {
      // Must be active or was active during this date
      final startDateOnly = DateTime(
        med.startDate.year,
        med.startDate.month,
        med.startDate.day,
      );
      if (dateOnly.isBefore(startDateOnly)) continue;

      if (!med.isOngoing && med.endDate != null) {
        final endDateOnly = DateTime(
          med.endDate!.year,
          med.endDate!.month,
          med.endDate!.day,
        );
        if (dateOnly.isAfter(endDateOnly)) continue;
      }

      if (!med.isScheduledOnWeekday(date.weekday)) continue;

      // For each reminder time
      for (int i = 0; i < med.reminderTimes.length; i++) {
        final time = med.reminderTimes[i];
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final existingLog = getLogFor(med.id, scheduledTime, i);

        items.add(
          ScheduledDoseItem(
            medicine: med,
            timeIndex: i,
            scheduledDateTime: scheduledTime,
            log: existingLog,
          ),
        );
      }
    }

    // Sort by scheduled time ascending
    items.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return items;
  }

  /// Marks a scheduled dose as taken, skipped, or missed.
  /// Prevents duplicate entries using the deterministic log ID.
  Future<bool> markDoseStatus({
    required ScheduledDoseItem item,
    required String status, // 'taken', 'skipped', 'missed'
    String? notes,
  }) async {
    if (_currentUserId == null) return false;

    final logId = item.deterministicLogId;
    final now = DateTime.now();

    final log = DoseLog(
      id: logId,
      userId: _currentUserId!,
      medicineId: item.medicine.id,
      medicineName: item.medicine.name,
      dosage: item.medicine.dosageDisplay,
      scheduledTime: item.scheduledDateTime,
      actionTime: status == 'taken' ? now : null,
      status: status,
      notes: notes,
      createdAt: now,
    );

    try {
      await _databaseService.recordDoseLog(log);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to record dose status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Calculates adherence percentage for today (0 - 100)
  double getTodayAdherence(List<Medicine> medicines) {
    final todayItems = getDoseItemsForDate(DateTime.now(), medicines);
    if (todayItems.isEmpty) return 100.0;

    final takenCount = todayItems.where((item) => item.isTaken).length;
    return (takenCount / todayItems.length) * 100.0;
  }

  /// Today's stats: taken, missed, pending
  Map<String, int> getTodayStats(List<Medicine> medicines) {
    final todayItems = getDoseItemsForDate(DateTime.now(), medicines);
    int taken = 0;
    int skipped = 0;
    int missed = 0;
    int pending = 0;

    for (final item in todayItems) {
      if (item.isTaken) {
        taken++;
      } else if (item.isSkipped) {
        skipped++;
      } else if (item.isMissed) {
        missed++;
      } else {
        pending++;
      }
    }

    return {
      'total': todayItems.length,
      'taken': taken,
      'skipped': skipped,
      'missed': missed,
      'pending': pending,
    };
  }

  /// Calculates past 7 days adherence data for trend charts
  List<DailyAdherenceData> getPast7DaysAdherence(List<Medicine> medicines) {
    final List<DailyAdherenceData> trend = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final items = getDoseItemsForDate(date, medicines);
      if (items.isEmpty) {
        trend.add(
          DailyAdherenceData(date: date, percentage: 100.0, totalDoses: 0),
        );
      } else {
        final taken = items.where((it) => it.isTaken).length;
        final pct = (taken / items.length) * 100.0;
        trend.add(
          DailyAdherenceData(
            date: date,
            percentage: pct,
            totalDoses: items.length,
          ),
        );
      }
    }

    return trend;
  }

  void clear() {
    _logsSubscription?.cancel();
    _currentUserId = null;
    _logs = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }
}

class DailyAdherenceData {
  final DateTime date;
  final double percentage;
  final int totalDoses;

  const DailyAdherenceData({
    required this.date,
    required this.percentage,
    required this.totalDoses,
  });
}
