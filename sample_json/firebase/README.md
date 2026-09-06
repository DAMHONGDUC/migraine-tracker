# firebase/ — Firestore data

Not a column-for-column copy of `local/`. Firestore holds only the **encrypted
form** of a health record, plus one configuration document per user.

| File | Path | Who can read/write |
| --- | --- | --- |
| `users.json` | `users/{uid}` | the owner only; `premium` is written by the RevenueCat webhook alone |
| `attacks.json` | `attacks/{docId}` | filtered by `userId` |
| `medications.json` | `medications/{docId}` | filtered by `userId` |
| `medication_reminders.json` | `medication_reminders/{docId}` | filtered by `userId` |
| `notifications.json` | `notifications/{docId}` | filtered by `userId` |
| `sync_keys.json` | `sync_keys/{uid}` | **no client at all** — only the `getSyncKey` callable, through the Admin SDK |
| `app_config.json` | `app_config/app` and `app_config/{email}` | `app` readable by anyone; a row only by the address it names; neither writable by any client |

Two files here are not collections:

- `payload_plaintext.json` — **what is actually inside `payload`** once
  decrypted, keyed by `<collection>/<docId>`. This is what `AttackPayloadCodec`
  and the other three codecs encode; it exists in this form nowhere on the
  server.
- `push_pressure_alert.json` — the FCM message the `functions/src/index.ts`
  cron sends.

`all_collections.json` merges the 7 collections, generated from the files
above.

## Conventions

- **`__id__` is the document id, not a field.** In Firestore it is the
  document's name; it has to sit inside the object here to be readable at all.
- **Dates are ISO-8601 UTC.** In Firestore they are `Timestamp`s.
- **`app_config` holds two shapes in one collection.** `app_config/app` is the
  one document that applies to every install; every other id is an email
  address, lower-cased, and applies only to that person. Nothing in `app` may
  name a person — it is world-readable, because the force-update check runs
  before any sign-in.
- **Flat, not subcollections.** `attacks/{docId}`, not
  `users/{uid}/attacks/{docId}`, which makes `userId` the **entire boundary**
  between two users' data: the rules check it on every operation, and **every
  query must filter on it** (`OwnedCollection` is the only thing that builds a
  reference to these collections).
- **`payload` / `nonce` / `mac` are all base64.** In these sample files they
  are **random bytes of the right length** and decrypt to nothing — a 12-byte
  nonce, a 16-byte mac, and ciphertext as long as its plaintext. To see the
  contents, read `payload_plaintext.json`.
- **Those three fields are exempt from indexing** (`fieldOverrides` in
  `firestore.indexes.json`): only `userId` and `updatedAt` are ever queried.
- **The pull query needs a composite index of `userId` + `updatedAt` per
  collection.**

## Cases included on purpose

- `users[0]` — a signed-in user: full account fields, registered for alerts,
  `premium: true`, and the `lastAlertAt` / `lastAlertEventId` the cron writes.
- `users[1]` — an anonymous user: **only** geohash5, fcmToken, alertThreshold,
  tz, premium. No name, no email, and no health records at all (hard rule 1).
- `users[2]` — location/notification permission never granted: no geohash and
  no token, so the cron skips them.
- Every synced collection carries **one `deleted: true` document** — a
  tombstone that has been pushed: `payload` / `nonce` / `mac` blanked, leaving
  `updatedAt` to settle which side is newer. Deleting a medication means its
  reminders need their own tombstones, because Firestore has no cascade.
- **The server holds only what was confirmed.** The 2nd and 4th attacks in
  `local/attacks.json` have `syncedRevision: null` and so are absent here; the
  5th attack here is the `revision 4` copy, older than the `revision 5` on the
  device.
- `app_config/app` — premium on, and a published build with
  `enable_force_update: false`, which is the shape that blocks nobody. A
  release edits this one document; there is no history to keep.
- `app_config` rows — one address granted premium *and* the Dev group (the App
  Review account), one granted only the Dev group (a TestFlight tester), and
  one `blocked`. Every field is absent unless granted: three rows is the whole
  collection, not a sample of a longer list.

## Warning

`sync_keys.json` is a **placeholder**, not a real key, and decrypts nothing.
The real key is held by the server, which means **sync is encrypted but NOT
end-to-end** — Google infrastructure can decrypt it. Never write copy that
implies otherwise.
