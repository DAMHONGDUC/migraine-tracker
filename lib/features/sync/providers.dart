import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/db/database_provider.dart';
import '../../core/storage/secure_store.dart';
import '../attacks/data/repositories/drift_attack_sync_store.dart';
import '../attacks/domain/entities/attack.dart';
import '../medications/data/repositories/drift_medication_reminder_sync_store.dart';
import '../medications/data/repositories/drift_medication_sync_store.dart';
import '../medications/domain/entities/medication.dart';
import '../medications/domain/entities/medication_reminder.dart';
import '../medications/providers.dart';
import '../notifications/data/repositories/drift_app_notification_sync_store.dart';
import '../notifications/domain/entities/app_notification.dart';
import 'data/repositories/firestore_sync_repository.dart';
import 'data/repositories/functions_sync_key_repository.dart';
import 'data/repositories/prefs_sync_cursor_store.dart';
import 'data/services/aes_gcm_attack_cipher.dart';
import 'data/services/sync_write_through_service.dart';
import 'domain/entities/sync_status.dart';
import 'domain/repositories/remote_sync_repository.dart';
import 'domain/repositories/sync_cursor_store.dart';
import 'domain/repositories/sync_key_repository.dart';
import 'domain/services/app_notification_payload_codec.dart';
import 'domain/services/attack_cipher.dart';
import 'domain/services/attack_payload_codec.dart';
import 'domain/services/medication_payload_codec.dart';
import 'domain/services/medication_reminder_payload_codec.dart';
import 'domain/services/sync_service.dart';
import 'presentation/controllers/sync_controller.dart';

final syncKeyRepositoryProvider = Provider<SyncKeyRepository>(
  (ref) => FunctionsSyncKeyRepository(
    FirebaseFunctions.instanceFor(region: FirebaseConstants.functionsRegion),
  ),
);

final remoteSyncRepositoryProvider = Provider<RemoteSyncRepository>(
  (ref) => FirestoreSyncRepository(FirebaseFirestore.instance),
);

final syncCursorStoreProvider = Provider<SyncCursorStore>(
  (ref) => PrefsSyncCursorStore(ref.watch(secureStoreProvider)),
);

final attackCipherProvider = Provider<AttackCipher>(
  (ref) => const AesGcmAttackCipher(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);

  return SyncService(
    // Order matters: a reminder points at a medication, so medications have to land before the reminders that reference them.
    <SyncBinding<dynamic>>[
      SyncBinding<Medication>(
        DriftMedicationSyncStore(db),
        const MedicationPayloadCodec(),
      ),
      SyncBinding<MedicationReminder>(
        DriftMedicationReminderSyncStore(db),
        const MedicationReminderPayloadCodec(),
      ),
      SyncBinding<Attack>(DriftAttackSyncStore(db), const AttackPayloadCodec()),
      // Last: a notification names the reminder and medication it came from, so both are already here by the time the list renders it.
      SyncBinding<AppNotification>(
        DriftAppNotificationSyncStore(db),
        const AppNotificationPayloadCodec(),
      ),
    ],
    ref.watch(remoteSyncRepositoryProvider),
    ref.watch(syncKeyRepositoryProvider),
    ref.watch(syncCursorStoreProvider),
    ref.watch(attackCipherProvider),
    // The rows sync; the OS notifications they stand for do not.
    () => ref.read(remindersControllerProvider).rescheduleAll(),
  );
});

/// The only sync state the UI may read (see [SyncController]).
final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

/// Pushes every local change as it is made. Started by the app root, which is also what keeps it alive (hard rule 12).
final syncWriteThroughProvider = Provider<SyncWriteThroughService>((ref) {
  final SyncWriteThroughService service = SyncWriteThroughService(
    ref.watch(databaseProvider),
    () => ref.read(syncControllerProvider.notifier).pushPending(),
  );

  // The debounce timer outlives the widget tree otherwise, which a widget test reports as a pending timer rather than as a leak.
  ref.onDispose(service.dispose);
  return service;
});
