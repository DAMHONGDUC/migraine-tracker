import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
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

/// One kind of record and the two things sync needs to move it: where it lives locally, and how it becomes a payload.
class SyncBinding<T> {
  const SyncBinding(this.store, this.codec);

  final SyncLocalStore<T> store;
  final SyncPayloadCodec<T> codec;

  SyncCollection get collection => store.collection;
}

/// Moves the user's records between this device and their account: pull what changed elsewhere, then push what is still owed.
class SyncService {
  const SyncService(
    this._bindings,
    this._remote,
    this._keys,
    this._cursor,
    this._cipher,
    this._onRemindersPulled,
  );

  /// In [SyncCollection] order, which is load-bearing: a reminder points at a medication, so medications have to land first.
  final List<SyncBinding<dynamic>> _bindings;

  final RemoteSyncRepository _remote;
  final SyncKeyRepository _keys;
  final SyncCursorStore _cursor;
  final AttackCipher _cipher;

  /// Called after reminders came down.
  final Future<void> Function() _onRemindersPulled;

  /// Stands in for "pulled, found nothing". Everything is still newer than this, so recording it can never skip a record.
  static final DateTime _beginning = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  /// True when this account's attacks have never been pulled on this device, i.e. the history is about to arrive rather than already being on screen.
  Future<bool> isFirstPull(String uid) async =>
      await _cursor.lastPulledAt(uid, SyncCollection.attacks) == null;

  /// The whole pass: what changed elsewhere comes down, then what is still owed goes up. Launch and resume only — a local write goes up through [pushPending].
  Future<SyncOutcome> sync(String uid) async {
    final String key = await _keys.keyFor(uid);
    int pushed = 0;
    int pulled = 0;
    int unreadable = 0;
    bool remindersArrived = false;

    for (final SyncBinding<dynamic> binding in _bindings) {
      final SyncOutcome pull = await _pull(uid, binding, key);

      pulled += pull.pulled;
      unreadable += pull.unreadable;
      pushed += await _push(uid, binding, key, await binding.store.pendingChanges());
      if (binding.collection == SyncCollection.medicationReminders &&
          pull.pulled > 0) {
        remindersArrived = true;
      }
    }
    if (remindersArrived) await _onRemindersPulled();

    return SyncOutcome(pushed: pushed, pulled: pulled, unreadable: unreadable);
  }

  /// Everything the device still owes the server, and no pull — what a local write costs (hard rule 12).
  ///
  /// The key is fetched only once something is actually pending. Marking a
  /// record synced writes to its own table, which is itself what schedules the
  /// next push, so every real push is followed by one that finds nothing: that
  /// one has to cost four local queries and no network, or the chain would pay
  /// a `getSyncKey` call for nothing every time.
  Future<int> pushPending(String uid) async {
    String? key;
    int pushed = 0;

    for (final SyncBinding<dynamic> binding in _bindings) {
      final List<SyncRecord<dynamic>> pending = await binding.store
          .pendingChanges();

      if (pending.isEmpty) continue;
      pushed += await _push(uid, binding, key ??= await _keys.keyFor(uid), pending);
    }
    return pushed;
  }

  /// Deletes the account's whole synced history and forgets where the pull had got to (GDPR wipe, hard rule 8).
  Future<void> wipeRemote(String uid) async {
    await _remote.deleteAll(uid);
    await _cursor.clear();
  }

  /// Forgets everything tied to the account that just signed out. Local records are untouched — they are the source of truth, not a cache.
  Future<void> onSignedOut() async {
    _keys.forget();
    await _cursor.clear();
  }

  Future<int> _push(
    String uid,
    SyncBinding<dynamic> binding,
    String key,
    List<SyncRecord<dynamic>> pending,
  ) async {
    int pushed = 0;

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
      // Only now, once the server has it: a kill anywhere above costs a re-push next launch, never a lost record.
      if (record.isDeleted) {
        await binding.store.clearTombstone(record.id);
      } else {
        await binding.store.markSynced(record.id, record.revision);
      }
      pushed++;
    }
    return pushed;
  }

  Future<SyncOutcome> _pull(
    String uid,
    SyncBinding<dynamic> binding,
    String key,
  ) async {
    final SyncCollection collection = binding.collection;
    final DateTime? since = await _cursor.lastPulledAt(uid, collection);
    final List<EncryptedRecord> changes = await _remote.changesSince(
      uid,
      collection,
      since,
    );
    // The whole batch at once, index for index.
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
    }
    // - Saved only once the batch is through, so anything that threw leaves the cursor put and the next pass redoes the batch harmlessly.
    await _cursor.save(uid, collection, newest ?? since ?? _beginning);

    return SyncOutcome(pulled: pulled, unreadable: unreadable);
  }

  /// Null when the record could not be opened ([plaintext] is null) or will not parse.
  Object? _decodeOrNull(
    SyncBinding<dynamic> binding,
    EncryptedRecord change,
    String? plaintext,
  ) {
    if (plaintext == null) return null;
    try {
      return binding.codec.decode(plaintext, id: change.id);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.sync,
        'Decoding a synced ${binding.collection.name} record failed',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }
}
