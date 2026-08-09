import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/medication_reminder.dart';
import '../../domain/services/notification_scheduler.dart';

/// flutter_local_notifications implementation. Assumes timezone data has
/// been initialized once at app start (see medications/providers.dart).
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'medication_reminders';
  static const _channelName = 'Medication reminders';

  /// - `presentSound` is what makes a reminder audible on iOS: the plugin
  ///   builds the content's default sound from it, and it also governs the
  ///   foreground banner. Without it iOS delivers the reminder silently.
  /// - Always on, with no app-level switch — muting is the OS's own job
  ///   (Settings › Notifications, the ring switch, Focus).
  static const NotificationDetails _details = NotificationDetails(
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
  );

  /// Broadcast: nobody may be listening when a tap lands (the app can be
  /// mid-launch), and a single-subscription stream would keep that event
  /// buffered for whoever listened first.
  final StreamController<String> _taps = StreamController<String>.broadcast();

  /// True once the launch details have been handed over, so a resume does
  /// not reopen the screen the app was started on.
  bool _launchTapTaken = false;

  /// Wires the plugin up, including the tap callback. Called once, from the
  /// provider that builds this.
  ///
  /// The callback lives here rather than in the provider because the payload
  /// it carries is this class's own — [schedule] is what put it there.
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          // These drive the plugin's own willPresent handler; without them
          // iOS drops foreground notifications and reminders only show
          // backgrounded.
          defaultPresentAlert: true,
          defaultPresentSound: true,
          defaultPresentBanner: true,
          defaultPresentList: true,
        ),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );
  }

  Future<void> dispose() => _taps.close();

  @override
  Stream<String> get reminderTaps => _taps.stream;

  @override
  Future<String?> takeLaunchReminderId() async {
    if (_launchTapTaken) return null;
    _launchTapTaken = true;

    final NotificationAppLaunchDetails? details = await _plugin
        .getNotificationAppLaunchDetails();

    if (details == null || !details.didNotificationLaunchApp) return null;

    return _reminderIdOf(details.notificationResponse?.payload);
  }

  void _onResponse(NotificationResponse response) {
    final String? reminderId = _reminderIdOf(response.payload);

    if (reminderId != null) _taps.add(reminderId);
  }

  /// The payload a reminder carries is its own id and nothing else. The debug
  /// test notification has none, which is what an empty answer means here.
  String? _reminderIdOf(String? payload) =>
      payload == null || payload.isEmpty ? null : payload;

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
      // What the tap handler resolves back to a row in the notification
      // list. The id alone: no medication name, so nothing about the user's
      // health sits in an OS payload.
      payload: reminder.id,
      notificationDetails: _details,
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
      notificationDetails: _details,
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
