import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';
import '../utils/app_constants.dart';

/// Notification service managing scheduled local medicine reminders.
/// Follows modern Android notification policies and timezone scheduling.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize local notifications and timezone data.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('[NotificationService] Timezone init fallback to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android settings: use app launcher icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
            '[NotificationService] Notification clicked: ${response.payload}',
          );
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDesc,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Successfully initialized');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Request permissions for notifications on Android 13+ (POST_NOTIFICATIONS) and iOS.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final grantedNotification =
          await androidImplementation?.requestNotificationsPermission() ??
          false;
      return grantedNotification;
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Check whether notifications are enabled on this device.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Schedules daily or weekly recurring alarms for each reminder time of a medicine.
  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (!medicine.isActive) return;

    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      final time = medicine.reminderTimes[i];
      final notificationId = medicine.getNotificationId(i);

      final String body =
          medicine.instructions != null && medicine.instructions!.isNotEmpty
          ? '${medicine.dosageDisplay} • ${medicine.instructions}'
          : 'Prescribed dose: ${medicine.dosageDisplay}';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            category: AndroidNotificationCategory.reminder,
            ticker: 'Medicine Reminder',
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(''),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      try {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If reminder time has passed for today, move to tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        // Schedule repeating alarm at the given time of day
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          'Time to take ${medicine.name}',
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: '${medicine.id}|$i',
        );

        debugPrint(
          '[NotificationService] Scheduled notification #$notificationId for ${medicine.name} at ${time.hour}:${time.minute}',
        );
      } catch (e) {
        debugPrint(
          '[NotificationService] Error scheduling notification for ${medicine.name}: $e',
        );
      }
    }
  }

  /// Cancels all scheduled notification alarms for a given medicine.
  Future<void> cancelMedicineReminders(
    String medicineId,
    int reminderCount,
  ) async {
    for (int i = 0; i < reminderCount + 5; i++) {
      // Cancel by computing deterministic ID
      var hash = 0;
      final input = '${medicineId}_$i';
      for (int c = 0; c < input.length; c++) {
        hash = (31 * hash + input.codeUnitAt(c)) & 0x7FFFFFFF;
      }
      try {
        await _notificationsPlugin.cancel(hash);
      } catch (e) {
        debugPrint('[NotificationService] Cancel error for #$hash: $e');
      }
    }
  }

  /// Cancel all scheduled alarms across the entire app.
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[NotificationService] All notifications cancelled.');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling all: $e');
    }
  }

  /// Re-syncs and schedules all active medicines for the signed-in user.
  Future<void> rescheduleAll(List<Medicine> medicines) async {
    await cancelAllNotifications();
    for (final med in medicines) {
      if (med.isActive) {
        await scheduleMedicineReminder(med);
      }
    }
    debugPrint(
      '[NotificationService] Re-scheduled ${medicines.length} medicines.',
    );
  }
}
