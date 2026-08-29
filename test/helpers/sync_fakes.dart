import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_sync_store.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_reminder_sync_store.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_sync_store.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication_reminder.dart';
import 'package:migraine_tracker/features/sync/data/services/aes_gcm_attack_cipher.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_record.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/remote_sync_repository.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/sync_cursor_store.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/sync_key_repository.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/medication_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/medication_reminder_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/sync_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/sync_service.dart';

/// A real sync service over fake transport, for tests that need one.
SyncService syncServiceOver(
  AppDatabase db, {
  RemoteSyncRepository? remote,
  SyncCursorStore? cursor,
  Future<void> Function()? onRemindersPulled,
}) => SyncService(
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
  ],
  remote ?? FakeRemoteSyncRepository(),
  FakeSyncKeyRepository(),
  cursor ?? FakeSyncCursorStore(),
  const AesGcmAttackCipher(),
  onRemindersPulled ?? () async {},
);

/// Encrypts a record the way another device would have before uploading it.
Future<EncryptedRecord> encryptedFor<T>(
  String id,
  T value,
  SyncPayloadCodec<T> codec,
  DateTime updatedAt,
  String key,
) async => EncryptedRecord(
  id: id,
  updatedAt: updatedAt,
  payload: await const AesGcmAttackCipher().encrypt(
    plaintext: codec.encode(value),
    base64Key: key,
  ),
);

/// The server, as a map per collection.
class FakeRemoteSyncRepository implements RemoteSyncRepository {
  final Map<SyncCollection, Map<String, EncryptedRecord>> stored =
      <SyncCollection, Map<String, EncryptedRecord>>{};

  int putCount = 0;
  DateTime? lastSince;
  bool failNextPut = false;
  bool failNextQuery = false;
  bool failNextDeleteAll = false;

  /// Fails once this many puts have succeeded within a single sync.
  int? failPutAfter;

  int _putsThisRun = 0;

  /// Everything on the server, whatever collection it is in.
  Map<String, EncryptedRecord> get documents => <String, EncryptedRecord>{
    for (final Map<String, EncryptedRecord> byId in stored.values) ...byId,
  };

  Map<String, EncryptedRecord> of(SyncCollection collection) =>
      stored[collection] ?? <String, EncryptedRecord>{};

  @override
  Future<void> put(
    String uid,
    SyncCollection collection,
    EncryptedRecord record,
  ) async {
    if (failNextPut) {
      failNextPut = false;
      throw Exception('put failed');
    }
    if (failPutAfter != null && _putsThisRun >= failPutAfter!) {
      throw Exception('connection dropped');
    }
    _putsThisRun++;
    putCount++;
    (stored[collection] ??= <String, EncryptedRecord>{})[record.id] = record;
  }

  @override
  Future<List<EncryptedRecord>> changesSince(
    String uid,
    SyncCollection collection,
    DateTime? since,
  ) async {
    _putsThisRun = 0;
    lastSince = since;
    if (failNextQuery) {
      failNextQuery = false;
      throw Exception('query failed');
    }

    final List<EncryptedRecord> matching = of(collection).values
        .where((doc) => since == null || doc.updatedAt.isAfter(since))
        .toList();

    matching.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return matching;
  }

  @override
  Future<void> deleteAll(String uid) async {
    if (failNextDeleteAll) {
      failNextDeleteAll = false;
      throw Exception('delete failed');
    }
    stored.clear();
  }
}

/// A fixed key, standing in for the one the backend would mint.
class FakeSyncKeyRepository implements SyncKeyRepository {
  static const String _key = 'ZmFrZS1zeW5jLWtleS0zMi1ieXRlcy1sb25nLXh4eHg=';

  bool forgotten = false;

  String get key => _key;

  @override
  Future<String> keyFor(String uid) async => _key;

  @override
  void forget() => forgotten = true;
}

class FakeSyncCursorStore implements SyncCursorStore {
  final Map<String, DateTime> _positions = <String, DateTime>{};
  final Map<String, DateTime> _syncedAt = <String, DateTime>{};

  @override
  Future<DateTime?> lastPulledAt(String uid, SyncCollection collection) async =>
      _positions['${collection.name}_$uid'];

  @override
  Future<void> save(String uid, SyncCollection collection, DateTime at) async =>
      _positions['${collection.name}_$uid'] = at;

  @override
  Future<DateTime?> lastSyncedAt(String uid) async => _syncedAt[uid];

  @override
  Future<void> saveSyncedAt(String uid, DateTime at) async =>
      _syncedAt[uid] = at;

  @override
  Future<void> clear() async {
    _positions.clear();
    _syncedAt.clear();
  }
}
