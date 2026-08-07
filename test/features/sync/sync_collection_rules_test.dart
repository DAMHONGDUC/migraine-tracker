import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';

/// `SyncCollection`, `firestore.rules` and `firestore.indexes.json` are one
/// contract split across three files, and nothing but this test holds them
/// together. Both halves fail the same way — a query that dies at runtime,
/// logged as "Didn't finish" and nothing more.
///
/// They drifted once already: medications and reminders were added to the
/// enum while the rules still named only `attacks`, so every sync died on its
/// first query with `permission-denied`, and so did the dev seed.
void main() {
  late String rules;
  late Map<String, dynamic> indexes;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
    indexes =
        jsonDecode(File('firestore.indexes.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  List<Map<String, dynamic>> indexesFor(String collection) =>
      (indexes['indexes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((index) => index['collectionGroup'] == collection)
          .toList();

  for (final SyncCollection collection in SyncCollection.values) {
    test('firestore.rules allows the ${collection.name} collection', () {
      expect(
        rules,
        contains("'${collection.name}'"),
        reason:
            'SyncCollection.${collection.name} syncs to /${collection.name}, '
            'but firestore.rules never names it — every read and write there '
            'is denied.',
      );
    });

    test('${collection.name} has the composite index its query needs', () {
      // The pull filters on userId and orders by updatedAt. Firestore serves
      // an equality on one field with a range on another only from a
      // composite index; without it the query throws at runtime.
      final List<Map<String, dynamic>> found = indexesFor(collection.name);

      expect(
        found,
        hasLength(1),
        reason: 'no composite index declared for ${collection.name}',
      );
      expect(
        (found.single['fields'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((field) => field['fieldPath']),
        <String>['userId', 'updatedAt'],
        reason: 'the index must match the order the query filters in',
      );
    });
  }

  for (final SyncCollection collection in SyncCollection.values) {
    test('${collection.name} does not index its ciphertext', () {
      // Firestore indexes every field by default, ascending AND descending.
      // On payload that is roughly 1.4 KB of index for a 572-byte string
      // nothing ever queries — more index than document. Exempting the three
      // opaque fields cuts most of the stored bytes and speeds up each write.
      final Set<String?> exempt = (indexes['fieldOverrides'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where(
            (override) =>
                override['collectionGroup'] == collection.name &&
                (override['indexes'] as List<dynamic>).isEmpty,
          )
          .map((override) => override['fieldPath'] as String?)
          .toSet();

      expect(exempt, containsAll(<String>['payload', 'nonce', 'mac']));
    });
  }

  test('ownership is checked by functions, not copied per collection', () {
    // A copy of the condition per collection is a copy that can fall behind.
    expect(rules, contains('function ownsStored()'));
    expect(
      rules,
      contains('function ownsIncoming()'),
      reason:
          'without the incoming-document check a user can rewrite userId to '
          "someone else's, planting a record in their account",
    );
  });

  test('read is its own rule, never folded in with write', () {
    // Folding them means a disjunction covering creates, which leaves a
    // branch constraining nothing — Firestore then cannot prove a query safe
    // and denies EVERY query while the file still looks right. Proved by
    // functions/test/firestoreRules.test.ts against the emulator.
    // Asserted as four separate verbs rather than "no read, write anywhere":
    // sync_keys uses `allow read, write: if false` quite correctly.
    for (final String verb in <String>['read', 'create', 'update', 'delete']) {
      expect(
        rules,
        contains('allow $verb: if isSynced(collection)'),
        reason: '$verb must be its own rule for the synced collections',
      );
    }
  });

  test('the rules do not hand out every collection at once', () {
    // At the root a bare `{collection}` would match sync_keys and app_updates
    // too, not just the synced ones.
    expect(rules, contains('collection in ['));
  });
}
