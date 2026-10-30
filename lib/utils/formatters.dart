import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatting helpers for dates, times, and medication information.
class Formatters {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat(
    'MMM dd, yyyy • hh:mm a',
  );
  static final DateFormat _shortDate = DateFormat('EEE, MMM d');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE');

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateFormat.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _shortDate.format(date);
  }

  static String formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    return _timeFormat.format(time);
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return _timeFormat.format(dt);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  static String formatDosage(double amount, String unit) {
    final cleanAmount = amount % 1 == 0
        ? amount.toInt().toString()
        : amount.toString();
    return '$cleanAmount $unit';
  }

  static String weekdayName(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  static String formatDaysList(List<int> days) {
    if (days.isEmpty || days.length == 7) {
      return 'Every day';
    }
    final sorted = List<int>.from(days)..sort();
    return sorted.map(weekdayName).join(', ');
  }
}
