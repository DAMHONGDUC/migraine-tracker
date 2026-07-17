import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import 'data/repositories/drift_medication_reminder_repository.dart';
import 'data/repositories/drift_medication_repository.dart';
import 'data/services/local_notification_scheduler.dart';
import 'domain/entities/medication.dart';
import 'domain/repositories/medication_reminder_repository.dart';
import 'domain/repositories/medication_repository.dart';
import 'domain/services/notification_scheduler.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => DriftMedicationRepository(ref.watch(databaseProvider)),
);

final medicationsStreamProvider = StreamProvider<List<Medication>>(
  (ref) => ref.watch(medicationRepositoryProvider).watchAll(),
);

final medicationReminderRepositoryProvider =
    Provider<MedicationReminderRepository>(
      (ref) => DriftMedicationReminderRepository(ref.watch(databaseProvider)),
    );

final medicationRemindersStreamProvider =
    StreamProvider<List<MedicationReminderView>>(
      (ref) => ref.watch(medicationReminderRepositoryProvider).watchAll(),
    );

/// The flutter_local_notifications plugin, initialized once (timezone setup
/// happens in main()). Override in tests with a fake NotificationScheduler.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  return LocalNotificationScheduler(plugin);
});
