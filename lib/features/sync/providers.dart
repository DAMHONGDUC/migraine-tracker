import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/l10n/locale_provider.dart';
import '../attacks/providers.dart';
import 'data/repositories/firestore_attack_repository.dart';
import 'data/repositories/functions_sync_key_repository.dart';
import 'data/repositories/prefs_sync_cursor_store.dart';
import 'data/services/aes_gcm_attack_cipher.dart';
import 'domain/entities/sync_status.dart';
import 'domain/repositories/remote_attack_repository.dart';
import 'domain/repositories/sync_cursor_store.dart';
import 'domain/repositories/sync_key_repository.dart';
import 'domain/services/attack_cipher.dart';
import 'domain/services/attack_sync_service.dart';
import 'presentation/controllers/sync_controller.dart';

/// Same region as the functions themselves — the default (us-central1) would
/// miss them, and Firestore lives in europe-west1 for GDPR.
const String syncFunctionsRegion = 'europe-west1';

final syncKeyRepositoryProvider = Provider<SyncKeyRepository>(
  (ref) => FunctionsSyncKeyRepository(
    FirebaseFunctions.instanceFor(region: syncFunctionsRegion),
  ),
);

final remoteAttackRepositoryProvider = Provider<RemoteAttackRepository>(
  (ref) => FirestoreAttackRepository(FirebaseFirestore.instance),
);

final syncCursorStoreProvider = Provider<SyncCursorStore>(
  (ref) => PrefsSyncCursorStore(ref.watch(sharedPreferencesProvider)),
);

final attackCipherProvider = Provider<AttackCipher>(
  (ref) => const AesGcmAttackCipher(),
);

final attackSyncServiceProvider = Provider<AttackSyncService>(
  (ref) => AttackSyncService(
    ref.watch(attackSyncRepositoryProvider),
    ref.watch(remoteAttackRepositoryProvider),
    ref.watch(syncKeyRepositoryProvider),
    ref.watch(syncCursorStoreProvider),
    ref.watch(attackCipherProvider),
  ),
);

/// The only sync state the UI may read (see [SyncController]).
final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

/// True while a sync is in flight. Watched by the Account screen and by
/// Settings' Account row, and nowhere else (hard rule 12).
final isSyncingProvider = Provider<bool>(
  (ref) => ref.watch(syncControllerProvider).isSyncing,
);
