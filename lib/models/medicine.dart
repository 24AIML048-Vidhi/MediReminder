import 'dart:convert';
import 'package:flutter/material.dart';

/// Data model representing a prescribed medication schedule.
class Medicine {
  final String id;
  final String userId;
  final String name;
  final double dosageAmount;
  final String dosageUnit;
  final String form;
  final String? instructions;
  final String? doctorName;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isOngoing;
  final String
  frequency; // 'once_daily', 'twice_daily', 'three_times_daily', 'custom'
  final List<TimeOfDay> reminderTimes;
  final List<int>
  selectedDays; // 1 = Monday ... 7 = Sunday. Empty means all days.
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.form,
    this.instructions,
    this.doctorName,
    required this.startDate,
    this.endDate,
    this.isOngoing = true,
    required this.frequency,
    required this.reminderTimes,
    this.selectedDays = const [],
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted dosage display string (e.g. "500 mg")
  String get dosageDisplay {
    final clean = dosageAmount % 1 == 0
        ? dosageAmount.toInt().toString()
        : dosageAmount.toString();
    return '$clean $dosageUnit';
  }

  /// Whether this medicine is scheduled on a given weekday (1..7)
  bool isScheduledOnWeekday(int weekday) {
    if (selectedDays.isEmpty) return true;
    return selectedDays.contains(weekday);
  }

  /// Determines the next upcoming dose relative to [from] (defaults to DateTime.now())
  DateTime? getNextDoseTime([DateTime? from]) {
    if (!isActive) return null;
    final now = from ?? DateTime.now();

    // If medicine has ended before today
    if (!isOngoing && endDate != null) {
      final endOfDay = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23,
        59,
        59,
      );
      if (now.isAfter(endOfDay)) return null;
    }

    // Look ahead up to 14 days for the next scheduled dose
    for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
      final checkDate = now.add(Duration(days: dayOffset));
      final dateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);

      // Verify date is within start and end range
      final startDateOnly = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      if (dateOnly.isBefore(startDateOnly)) continue;

      if (!isOngoing && endDate != null) {
        final endDateOnly = DateTime(
          endDate!.year,
          endDate!.month,
          endDate!.day,
        );
        if (dateOnly.isAfter(endDateOnly)) return null;
      }

      // Check if scheduled on this weekday
      if (!isScheduledOnWeekday(checkDate.weekday)) continue;

      // Sort reminder times
      final sortedTimes = List<TimeOfDay>.from(reminderTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );

      for (final time in sortedTimes) {
        final scheduledDateTime = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          time.hour,
          time.minute,
        );

        if (scheduledDateTime.isAfter(now)) {
          return scheduledDateTime;
        }
      }
    }

    return null;
  }

  /// Deterministic 32-bit positive integer for Android notification scheduling.
  int getNotificationId(int timeIndex) {
    // Generate stable hash from medicine id and time slot index
    var hash = 0;
    final input = '${id}_$timeIndex';
    for (int i = 0; i < input.length; i++) {
      hash = (31 * hash + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dosageAmount': dosageAmount,
      'dosageUnit': dosageUnit,
      'form': form,
      'instructions': instructions,
      'doctorName': doctorName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isOngoing': isOngoing,
      'frequency': frequency,
      'reminderTimes': reminderTimes
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList(),
      'selectedDays': selectedDays,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map, String docId) {
    dynamic rawTimes = map['reminderTimes'];
    if (rawTimes is String) {
      try {
        rawTimes = jsonDecode(rawTimes);
      } catch (_) {
        rawTimes = [];
      }
    }

    final timesList = (rawTimes as List<dynamic>? ?? []).map((e) {
      final parts = e.toString().split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      return const TimeOfDay(hour: 8, minute: 0);
    }).toList();

    dynamic rawDays = map['selectedDays'];
    if (rawDays is String) {
      try {
        rawDays = jsonDecode(rawDays);
      } catch (_) {
        rawDays = [];
      }
    }

    final isOngoingVal = map['isOngoing'];
    final bool isOngoing = isOngoingVal is int
        ? isOngoingVal == 1
        : (isOngoingVal as bool? ?? true);

    final isActiveVal = map['isActive'];
    final bool isActive = isActiveVal is int
        ? isActiveVal == 1
        : (isActiveVal as bool? ?? true);

    return Medicine(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dosageAmount: (map['dosageAmount'] as num?)?.toDouble() ?? 1.0,
      dosageUnit: map['dosageUnit'] as String? ?? 'tablet(s)',
      form: map['form'] as String? ?? 'Tablet',
      instructions: map['instructions'] as String?,
      doctorName: map['doctorName'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString())
          : null,
      isOngoing: isOngoing,
      frequency: map['frequency'] as String? ?? 'once_daily',
      reminderTimes: timesList.isNotEmpty
          ? timesList
          : [const TimeOfDay(hour: 8, minute: 0)],
      selectedDays: (rawDays as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      notes: map['notes'] as String?,
      isActive: isActive,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Medicine copyWith({
    String? id,
    String? userId,
    String? name,
    double? dosageAmount,
    String? dosageUnit,
    String? form,
    String? instructions,
    String? doctorName,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOngoing,
    String? frequency,
    List<TimeOfDay>? reminderTimes,
    List<int>? selectedDays,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      form: form ?? this.form,
      instructions: instructions ?? this.instructions,
      doctorName: doctorName ?? this.doctorName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isOngoing: isOngoing ?? this.isOngoing,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      selectedDays: selectedDays ?? this.selectedDays,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
