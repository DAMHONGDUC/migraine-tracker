import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/storage/secure_store.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/presentation/controllers/check_in_reminder_controller.dart';
import 'package:migraine_tracker/features/daily_log/providers.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/notifications/domain/services/notification_scheduler.dart';
import 'package:migraine_tracker/features/notifications/providers.dart';

/// Records what it was asked to arm; everything else is here because the interface has it.
class _Scheduler implements NotificationScheduler {
  final List<DateTime> armed = <DateTime>[];
  int cancels = 0;
  bool permission = true;

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<void> scheduleCheckIn({
    required DateTime when,
    required String title,
    required String body,
  }) async => armed.add(when);

  @override
  Future<void> cancelCheckIn() async => cancels++;

  @override
  Stream<String> get reminderTaps => const Stream<String>.empty();

  @override
  Future<String?> takeLaunchReminderId() async => null;

  @override
  Future<void> schedule(
    MedicationReminder reminder, {
    required String medicationName,
    required String title,
    required String bodyTemplate,
  }) async {}

  @override
  Future<void> cancel(String reminderId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleTest({
    required String title,
    required String body,
    Duration delay = const Duration(seconds: 10),
  }) async {}
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _Scheduler scheduler;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final SecureStore prefs = await SecureStore.open();

    db = AppDatabase(NativeDatabase.memory());
    scheduler = _Scheduler();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        secureStoreProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CheckInReminderController controller() =>
      container.read(checkInReminderControllerProvider.notifier);

  test('off until asked for, and 20:30 when it is', () {
    final CheckInReminderSettings settings = container.read(
      checkInReminderControllerProvider,
    );

    expect(settings.enabled, isFalse);
    expect(settings.hour, 20);
    expect(settings.minute, 30);
  });

  test('turning it off cancels rather than arming', () async {
    await controller().setEnabled(false);

    expect(scheduler.armed, isEmpty);
    expect(scheduler.cancels, greaterThan(0));
  });

  test('an OS refusal leaves the switch off', () async {
    scheduler.permission = false;

    expect(await controller().setEnabled(true), isFalse);
    expect(container.read(checkInReminderControllerProvider).enabled, isFalse);
  });

  test('a day already answered moves the nudge to tomorrow', () async {
    await container
        .read(dailyLogRepositoryProvider)
        .save(DailyLog(day: DateTime.now(), sleepQuality: 3));

    await controller().setEnabled(true);
    // The time chosen is irrelevant: today is answered, so it cannot be today.
    await controller().setTime(1);

    expect(scheduler.armed, isNotEmpty);
    expect(
      scheduler.armed.last.isAfter(DateTime.now()),
      isTrue,
      reason: 'never arms an instant in the past',
    );
    expect(scheduler.armed.last.day, isNot(DateTime.now().day));
  });

  test('an unanswered day keeps the nudge on that day', () async {
    await controller().setEnabled(true);

    // 23:59: still ahead of now on every run but the last minute of the day, which is what makes this assertion about the rule rather than the clock.
    await controller().setTime(23 * 60 + 59);

    expect(scheduler.armed.last.day, DateTime.now().day);
    expect(scheduler.armed.last.hour, 23);
  });
}
