import '../../../../core/logging/app_logger.dart';
import '../entities/encrypted_payload.dart';
import '../entities/encrypted_record.dart';
import '../entities/sync_collection.dart';
import '../entities/sync_outcome.dart';
import '../entities/sync_record.dart';
import '../repositories/remote_sync_repository.dart';
import '../repositories/sync_cursor_store.dart';
import '../repositories/sync_key_repository.dart';
import '../repositories/sync_local_store.dart';
import 'attack_cipher.dart';
import 'sync_payload_codec.dart';

/// How far a sync has got, 0 to 1.
///
/// Reported against a fixed number of steps — two per collection — rather
/// than against records, so it only ever climbs. Counting records would mean
/// discovering more work mid-pass, and a bar that jumps backwards reads as a
/// bug even when the sync is fine.
typedef SyncProgressCallback = void Function(double fraction);

/// One kind of record and the two things sync needs to move it: where it
/// lives locally, and how it becomes a payload.
class SyncBinding<T> {
  const SyncBinding(this.store, this.codec);

  final SyncLocalStore<T> store;
  final SyncPayloadCodec<T> codec;

  SyncCollection get collection => store.collection;
}

/// Moves the user's records between this device and their account: pull what
/// changed elsewhere, then push what is still owed.
///
/// Pull goes first because the other order re-downloads everything it just
/// uploaded — a device signing in has no cursor, so its own fresh writes come
/// straight back. Pulling first also settles which version won before the
/// push decides what is left to send.
///
/// Nothing here ever blocks a screen. It is called unawaited from the app's
/// own triggers, in the same best-effort shape as `WeatherAttachService`, and
/// a pass that fails simply leaves the work pending for the next one.
class SyncService {
  const SyncService(
    this._bindings,
    this._remote,
    this._keys,
    this._cursor,
    this._cipher,
    this._onRemindersPulled,
  );

  /// In [SyncCollection] order, which is load-bearing: a reminder points at a
  /// medication, so medications have to land first.
  final List<SyncBinding<dynamic>> _bindings;

  final RemoteSyncRepository _remote;
  final SyncKeyRepository _keys;
  final SyncCursorStore _cursor;
  final AttackCipher _cipher;

  /// Called after reminders came down. The rows travel but the scheduled OS
  /// notifications do not — those are local to each device and have to be
  /// laid down again, or the reminders exist and never fire.
  final Future<void> Function() _onRemindersPulled;

  /// Stands in for "pulled, found nothing". Everything is still newer than
  /// this, so recording it can never skip a record.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  /// True when this account's attacks have never been pulled on this device,
  /// i.e. the history is about to arrive rather than already being on screen.
  Future<bool> isFirstPull(String uid) async =>
      await _cursor.lastPulledAt(uid, SyncCollection.attacks) == null;

  Future<SyncOutcome> sync(
    String uid, {
    SyncProgressCallback? onProgress,
  }) async {
    final int steps = _bindings.length * 2;
    final String key = await _keys.keyFor(uid);
    int stepsDone = 0;
    int pushed = 0;
    int pulled = 0;
    int unreadable = 0;
    bool remindersArrived = false;

    /// [within] is how far the step in flight has got, so the fraction moves
    /// during a long collection instead of sitting still and then jumping.
    void report(double within) =>
        onProgress?.call((stepsDone + within) / steps);

    report(0);
    for (final SyncBinding<dynamic> binding in _bindings) {
      final SyncOutcome pull = await _pull(uid, binding, key, report);

      stepsDone++;
      report(0);
      pulled += pull.pulled;
      unreadable += pull.unreadable;
      pushed += await _push(uid, binding, key, report);
      stepsDone++;
      report(0);
      if (binding.collection == SyncCollection.medicationReminders &&
          pull.pulled > 0) {
        remindersArrived = true;
      }
    }
    if (remindersArrived) await _onRemindersPulled();

    return SyncOutcome(pushed: pushed, pulled: pulled, unreadable: unreadable);
  }

  /// Deletes the account's whole synced history and forgets where the pull
  /// had got to (GDPR wipe, hard rule 8).
  Future<void> wipeRemote(String uid) async {
    await _remote.deleteAll(uid);
    await _cursor.clear();
  }

  /// Forgets everything tied to the account that just signed out. Local
  /// records are untouched — they are the source of truth, not a cache.
  Future<void> onSignedOut() async {
    _keys.forget();
    await _cursor.clear();
  }

  Future<int> _push(
    String uid,
    SyncBinding<dynamic> binding,
    String key,
    SyncProgressCallback report,
  ) async {
    final List<SyncRecord<dynamic>> pending = await binding.store
        .pendingChanges();
    int pushed = 0;
    int done = 0;

    for (final SyncRecord<dynamic> record in pending) {
      final Object? value = record.value;
      final EncryptedPayload? payload = value == null
          ? null
          : await _cipher.encrypt(
              plaintext: binding.codec.encode(value),
              base64Key: key,
            );

      await _remote.put(
        uid,
        binding.collection,
        EncryptedRecord(
          id: record.id,
          updatedAt: record.updatedAt,
          payload: payload,
        ),
      );
      // Only now, once the server has it: a kill anywhere above costs a
      // re-push next launch, never a lost record.
      if (record.isDeleted) {
        await binding.store.clearTombstone(record.id);
      } else {
        await binding.store.markSynced(record.id, record.revision);
      }
      pushed++;
      done++;
      report(done / pending.length);
    }
    return pushed;
  }

  Future<SyncOutcome> _pull(
    String uid,
    SyncBinding<dynamic> binding,
    String key,
    SyncProgressCallback report,
  ) async {
    final SyncCollection collection = binding.collection;
    final DateTime? since = await _cursor.lastPulledAt(uid, collection);
    final List<EncryptedRecord> changes = await _remote.changesSince(
      uid,
      collection,
      since,
    );
    // The whole batch at once, index for index: an implementation is then
    // free to take the AES off this isolate, which is the only part of a
    // pull that holds the UI thread (the writes below await real I/O).
    final List<String?> plaintexts = await _cipher.decryptAll(
      payloads: <EncryptedPayload?>[
        for (final EncryptedRecord change in changes)
          change.isDeleted ? null : change.payload,
      ],
      base64Key: key,
    );
    DateTime? newest = since;
    int pulled = 0;
    int unreadable = 0;
    int done = 0;

    for (final (int index, EncryptedRecord change) in changes.indexed) {
      if (change.isDeleted) {
        if (await binding.store.applyRemoteDeletion(
          change.id,
          change.updatedAt,
        )) {
          pulled++;
        }
      } else {
        final Object? value = _decodeOrNull(binding, change, plaintexts[index]);

        if (value == null) {
          unreadable++;
        } else if (await binding.store.applyRemote(value, change.updatedAt)) {
          pulled++;
        }
      }
      if (newest == null || change.updatedAt.isAfter(newest)) {
        newest = change.updatedAt;
      }
      done++;
      report(done / changes.length);
    }
    // - Saved only once the batch is through: anything that threw above leaves
    //   the cursor put, and the next pass redoes the batch harmlessly.
    // - Always saved, even when nothing came back, or an account with no
    //   records yet would count as never-pulled on every single launch.
    await _cursor.save(uid, collection, newest ?? since ?? _beginning);

    return SyncOutcome(pulled: pulled, unreadable: unreadable);
  }

  /// Null when the record could not be opened ([plaintext] is null) or will
  /// not parse. Counted and skipped rather than retried forever: the
  /// ciphertext will not change, so one bad record must never wedge every
  /// later one behind it. The count travels out in [SyncOutcome] because
  /// domain code does not report errors itself.
  Object? _decodeOrNull(
    SyncBinding<dynamic> binding,
    EncryptedRecord change,
    String? plaintext,
  ) {
    if (plaintext == null) return null;
    try {
      return binding.codec.decode(plaintext, id: change.id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Decoding a synced ${binding.collection.name} record failed',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }
}
