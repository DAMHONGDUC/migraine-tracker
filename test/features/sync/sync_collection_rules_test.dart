import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';

/// `SyncCollection` and `firestore.rules` are one contract split across two
/// languages, and nothing but this test holds them together.
///
/// They drifted once already: medications and reminders were added to the
/// enum while the rules still named only `attacks`, so every sync died on its
/// first query with `permission-denied` — and so did the dev seed, which
/// wipes the account copy before it reseeds. Both symptoms, one missing line.
void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  for (final SyncCollection collection in SyncCollection.values) {
    test('firestore.rules allows the ${collection.name} subcollection', () {
      expect(
        rules,
        contains("'${collection.name}'"),
        reason:
            'SyncCollection.${collection.name} syncs to '
            'users/{uid}/${collection.name}, but firestore.rules never names '
            'it — every read and write there is denied.',
      );
    });
  }

  test('the rules do not hand out every subcollection at once', () {
    // A bare `{collection}` with no allowlist would grant a client read and
    // write on anything added under users/{uid} later, including something
    // meant to be server-only — sync_keys is denied outright for exactly
    // that reason.
    expect(rules, contains('collection in ['));
  });
}
