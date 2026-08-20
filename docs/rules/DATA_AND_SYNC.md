# Data, schemas and Firestore

Hard rules 14 and 15. Sync's own rules are in `lib/features/sync/CLAUDE.md`.

## 14. Never put two kinds of record in one table or collection

Each entity gets its own, on both sides: `Attacks`, `Medications`,
`MedicationReminders` in Drift; the top-level `attacks`, `medications`,
`medication_reminders` in Firestore. No shared table with a `type` column
standing in for three schemas.

**Firestore is flat and relational-shaped, by the owner's call.** Documents live
at `<collection>/{docId}` with a `userId` field; the id is the record's own
UUID. It replaced `users/{uid}/<collection>/{docId}` — equally separate, since a
subcollection is an independent collection, but with ownership in the path. The
flat shape reads like SQL and browses in the console, and costs the following.

- **`userId` is now the entire boundary between two users' records**, so two
  things must hold.
  - `firestore.rules` checks it both ways: `ownsStored()` on the document
    already there, `ownsIncoming()` on the one being written. Without the second
    a user can rewrite `userId` and plant a record in someone else's account.
  - **Every query filters on it.** Rules cannot be evaluated over a whole
    collection, so an unfiltered query is refused outright. `OwnedCollection`
    (`features/sync/data/repositories/`) is the only thing that builds a
    reference to these collections and has no method that omits the filter —
    never reach past it to `FirebaseFirestore.collection`.
- **`read` gets its own rule; never fold it into `allow read, write`.** A query
  has no single document, so Firestore proves it safe from the query's own
  filters — and that proof only works when the read condition is a plain
  constraint on a field. A combined rule needs a disjunction to cover creates
  (`resource == null || …`), which leaves a branch constraining nothing: the
  proof fails and **every query is denied while writes still succeed**. That
  shipped here, and `permission-denied` on a pull looks identical to rules that
  were never deployed. `functions/test/firestoreRules.test.ts` catches it — put
  the combined rule back and three query tests fail.
  - **Rules tests need the emulator started separately**: `firebase
    emulators:start --only firestore`, then `cd functions && npx vitest run
    test/firestoreRules.test.ts`. Not `emulators:exec` — that runs the script
    through the CLI's bundled Node, which cannot `require()` vitest's ESM (the
    snapshot that also broke the npm predeploy). The suite skips itself when no
    emulator answers, so plain `npm test` stays useful.
- **`payload`, `nonce` and `mac` are exempt from indexing** via `fieldOverrides`.
  Firestore indexes every field ascending and descending by default, so a
  572-byte ciphertext costs ~1.4 KB of index nothing queries — more index than
  document. Only `userId` and `updatedAt` are ever queried; anything new that is
  queryable must stay indexed.
- **The pull query needs a composite index per collection** (`userId` +
  `updatedAt`) in `firestore.indexes.json`: Firestore will not serve an equality
  on one field with a range on another without it, and a missing index fails at
  runtime, not at build. So `firebase deploy --only firestore:indexes` is a
  second deploy step alongside rules. `sync_collection_rules_test.dart` checks
  the enum against both files, but it can only prove the files are right, never
  that the project has them.
- **Firestore has no foreign keys here**, and had none in the old layout either.
  `userId` is a plain field: no referential integrity, no cascade. The only real
  FK is Drift's (`medicationId references Medications onDelete: cascade`), which
  is why deleting a medication tombstones its reminders explicitly.
- **`SyncTombstones` is the one shared table, deliberately.** It holds an id, a
  deletion time and which collection the id came from — no name, intensity or
  note, because the row itself is gone by then. It is sync bookkeeping, not a
  user record, and three copies of the same two columns would be three chances
  to disagree.

## 15. Never edit a schema version in place once any database has run it

Bump instead. `AppNotifications.type` was called `kind` in a v8 that had only
ever run on a dev device; renaming the column in place looked safe because v8
was unshipped, but that device stayed at v8 with the old column and no step
would ever fix it — every insert died with `table app_notifications has no
column named type`. **"Unshipped" means no database anywhere has run it, and
your own simulator counts.** v9 exists purely to undo this, and it *recreates*
the table rather than renaming a column: nothing records what the intermediate
v8 looked like, and a drop works whatever it was.
