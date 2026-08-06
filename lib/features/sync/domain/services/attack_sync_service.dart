import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/entities/attack_sync_record.dart';
import '../../../attacks/domain/repositories/attack_sync_repository.dart';
import '../entities/encrypted_attack.dart';
import '../entities/encrypted_payload.dart';
import '../entities/sync_outcome.dart';
import '../repositories/remote_attack_repository.dart';
import '../repositories/sync_cursor_store.dart';
import '../repositories/sync_key_repository.dart';
import 'attack_cipher.dart';
import 'attack_payload_codec.dart';

/// Moves attacks between this device and the account: pull what changed
/// elsewhere, then push what is still owed.
///
/// Pull goes first because the other order re-downloads everything it just
/// uploaded — a device signing in has no cursor, so its own fresh writes come
/// straight back. Pulling first also settles which version won before the
/// push decides what is left to send.
///
/// Nothing here ever blocks a screen. It is called unawaited from the app's
/// own triggers, in the same best-effort shape as `WeatherAttachService`, and
/// a pass that fails simply leaves the work pending for the next one.
class AttackSyncService {
  const AttackSyncService(
    this._local,
    this._remote,
    this._keys,
    this._cursor,
    this._cipher,
  );

  final AttackSyncRepository _local;
  final RemoteAttackRepository _remote;
  final SyncKeyRepository _keys;
  final SyncCursorStore _cursor;
  final AttackCipher _cipher;

  /// Stands in for "pulled, found nothing". Everything is still newer than
  /// this, so recording it can never skip a record.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  /// True when this account has never been pulled on this device, i.e. the
  /// history is about to arrive rather than already being on screen.
  Future<bool> isFirstPull(String uid) async =>
      await _cursor.lastPulledAt(uid) == null;

  Future<SyncOutcome> sync(String uid) async {
    final String key = await _keys.keyFor(uid);
    final SyncOutcome pull = await _pull(uid, key);
    final int pushed = await _push(uid, key);

    return SyncOutcome(
      pushed: pushed,
      pulled: pull.pulled,
      unreadable: pull.unreadable,
    );
  }

  /// Deletes the account's whole synced history and forgets where the pull
  /// had got to (GDPR wipe, hard rule 8).
  Future<void> wipeRemote(String uid) async {
    await _remote.deleteAll(uid);
    await _cursor.clear();
  }

  /// Forgets everything tied to the account that just signed out. Local
  /// attacks are untouched — they are the source of truth, not a cache.
  Future<void> onSignedOut() async {
    _keys.forget();
    await _cursor.clear();
  }

  Future<int> _push(String uid, String key) async {
    final List<AttackSyncRecord> pending = await _local.pendingChanges();
    int pushed = 0;

    for (final AttackSyncRecord record in pending) {
      final Attack? attack = record.attack;
      final EncryptedPayload? payload = attack == null
          ? null
          : await _cipher.encrypt(
              plaintext: AttackPayloadCodec.encode(attack),
              base64Key: key,
            );

      await _remote.put(
        uid,
        EncryptedAttack(
          id: record.id,
          updatedAt: record.updatedAt,
          payload: payload,
        ),
      );
      // Only now, once the server has it: a kill anywhere above costs a
      // re-push next launch, never a lost attack.
      if (record.isDeleted) {
        await _local.clearTombstone(record.id);
      } else {
        await _local.markSynced(record.id, record.revision);
      }
      pushed++;
    }
    return pushed;
  }

  Future<SyncOutcome> _pull(String uid, String key) async {
    final DateTime? since = await _cursor.lastPulledAt(uid);
    final List<EncryptedAttack> changes = await _remote.changesSince(uid, since);
    DateTime? newest = since;
    int pulled = 0;
    int unreadable = 0;

    for (final EncryptedAttack change in changes) {
      if (change.isDeleted) {
        if (await _local.applyRemoteDeletion(change.id, change.updatedAt)) {
          pulled++;
        }
      } else {
        final Attack? attack = await _decodeOrNull(change, key);

        if (attack == null) {
          unreadable++;
        } else if (await _local.applyRemote(attack, change.updatedAt)) {
          pulled++;
        }
      }
      if (newest == null || change.updatedAt.isAfter(newest)) {
        newest = change.updatedAt;
      }
    }
    // - Saved only once the batch is through: anything that threw above leaves
    //   the cursor put, and the next pass redoes the batch harmlessly.
    // - Always saved, even when nothing came back, or an account with no
    //   attacks yet would count as never-pulled on every single launch.
    await _cursor.save(uid, newest ?? since ?? _beginning);

    return SyncOutcome(pulled: pulled, unreadable: unreadable);
  }

  /// Null when the record cannot be opened or parsed. Counted and skipped
  /// rather than retried forever: the ciphertext will not change, so one bad
  /// record must never wedge every later one behind it. The count travels out
  /// in [SyncOutcome] because domain code does not report errors itself.
  Future<Attack?> _decodeOrNull(EncryptedAttack change, String key) async {
    final EncryptedPayload? payload = change.payload;

    if (payload == null) return null;
    try {
      return AttackPayloadCodec.decode(
        await _cipher.decrypt(payload: payload, base64Key: key),
        id: change.id,
      );
    } catch (_) {
      return null;
    }
  }
}
