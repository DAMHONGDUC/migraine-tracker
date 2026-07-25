import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/medication_reminder.dart';
import '../../domain/services/notification_scheduler.dart';

/// flutter_local_notifications implementation. Assumes timezone data has
/// been initialized once at app start (see medications/providers.dart).
class LocalNotificationScheduler implements NotificationScheduler {
  const LocalNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'medication_reminders';
  static const _channelName = 'Medication reminders';

  /// Stable per-reminder int id for the plugin (which keys on int).
  int _notificationId(String reminderId) => reminderId.hashCode & 0x7fffffff;

  @override
  Future<bool> ensurePermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  @override
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  }) async {
    await cancel(reminder.id);
    if (!reminder.enabled) return;

    await _plugin.zonedSchedule(
      id: _notificationId(reminder.id),
      title: title,
      body: bodyTemplate.replaceFirst('{name}', medicationName),
      scheduledDate: _nextInstanceOf(reminder.hour, reminder.minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
        ),
        // Present a banner + sound even while the app is in the foreground —
        // without these, iOS silently drops the notification when the app is
        // open, which reads as "reminders don't work" during testing.
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          presentList: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  @override
  Future<void> cancel(String reminderId) =>
      _plugin.cancel(id: _notificationId(reminderId));

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Fixed id for the debug test notification, kept far from reminder ids
  /// (which are masked hashCodes) so it never clobbers a real reminder.
  static const _testNotificationId = 2147483646;

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {
    await ensurePermission();
    await _plugin.zonedSchedule(
      id: _testNotificationId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          presentList: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // No matchDateTimeComponents → fires once, not daily.
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
