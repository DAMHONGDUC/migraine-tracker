import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_sync_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/sync/data/services/aes_gcm_attack_cipher.dart';
import 'package:migraine_tracker/features/sync/domain/entities/encrypted_attack.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/remote_attack_repository.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/sync_cursor_store.dart';
import 'package:migraine_tracker/features/sync/domain/repositories/sync_key_repository.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_payload_codec.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_sync_service.dart';

/// A real sync service over fake transport, for tests that need one but are
/// not testing sync itself.
AttackSyncService syncServiceOver(
  AppDatabase db, {
  RemoteAttackRepository? remote,
}) => AttackSyncService(
  DriftAttackSyncRepository(db),
  remote ?? FakeRemoteAttackRepository(),
  FakeSyncKeyRepository(),
  FakeSyncCursorStore(),
  const AesGcmAttackCipher(),
);

/// Encrypts an attack the way another device would have before uploading it.
Future<EncryptedAttack> encryptedFor(
  Attack attack,
  DateTime updatedAt,
  String key,
) async => EncryptedAttack(
  id: attack.id,
  updatedAt: updatedAt,
  payload: await const AesGcmAttackCipher().encrypt(
    plaintext: AttackPayloadCodec.encode(attack),
    base64Key: key,
  ),
);

/// The server, as a map. Failures are armed per test to stand in for a
/// dropped connection at a chosen point.
///
/// Also what `pumpApp` wires in, so no widget test ever reaches Firebase.
class FakeRemoteAttackRepository implements RemoteAttackRepository {
  final Map<String, EncryptedAttack> documents = <String, EncryptedAttack>{};

  int putCount = 0;
  DateTime? lastSince;
  bool failNextPut = false;
  bool failNextQuery = false;
  bool failNextDeleteAll = false;

  /// Fails once this many puts have succeeded within a single sync.
  int? failPutAfter;

  int _putsThisRun = 0;

  @override
  Future<void> put(String uid, EncryptedAttack record) async {
    if (failNextPut) {
      failNextPut = false;
      throw Exception('put failed');
    }
    if (failPutAfter != null && _putsThisRun >= failPutAfter!) {
      throw Exception('connection dropped');
    }
    _putsThisRun++;
    putCount++;
    documents[record.id] = record;
  }

  @override
  Future<List<EncryptedAttack>> changesSince(
    String uid,
    DateTime? since,
  ) async {
    _putsThisRun = 0;
    lastSince = since;
    if (failNextQuery) {
      failNextQuery = false;
      throw Exception('query failed');
    }

    final List<EncryptedAttack> matching = documents.values
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
    documents.clear();
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

  @override
  Future<DateTime?> lastPulledAt(String uid) async => _positions[uid];

  @override
  Future<void> save(String uid, DateTime at) async => _positions[uid] = at;

  @override
  Future<void> clear() async => _positions.clear();
}
