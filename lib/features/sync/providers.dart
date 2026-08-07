import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/db/database_provider.dart';
import '../../core/l10n/locale_provider.dart';
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
  (ref) => PrefsSyncCursorStore(ref.watch(sharedPreferencesProvider)),
);

final attackCipherProvider = Provider<AttackCipher>(
  (ref) => const AesGcmAttackCipher(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);

  return SyncService(
    // Order matters: a reminder points at a medication, so medications have
    // to land before the reminders that reference them.
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
      // Last: a notification names the reminder and medication it came
      // from, so both are already here by the time the list renders it.
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

/// True while a sync is in flight. Watched by `SyncScreen` to arm its manual
/// button, and nowhere else — no flow is ever gated on it (hard rule 12).
final isSyncingProvider = Provider<bool>(
  (ref) => ref.watch(syncControllerProvider).isSyncing,
);
