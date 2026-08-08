# sample_json — sample data

Fixtures to read and to test against, not files the app loads at runtime —
`DevSeedService` is still what seeds a dev device.

```
sample_json/
  local/      on-device data — 7 Drift (SQLite) tables, schema v9
  firebase/   Firestore data — 7 collections + the decrypted payloads
```

Both sides describe **the same user and the same set of ids**, so they can be
read against each other: an attack on the device and its encrypted document on
the server share one `id`.

The differences worth knowing, which are also the whole point of splitting the
two folders:

- **The device holds plaintext, the server holds only ciphertext.** Every
  intensity, note and medication name sits inside the base64 `payload`; the
  server can read only `userId` and `updatedAt`.
- **The server does not have everything the device has.** `export_records` and
  `sync_tombstones` never leave the device, and any row with
  `syncedRevision: null` has not been pushed yet either.
- **The device does not have everything the server has.** `users/{uid}`,
  `sync_keys/{uid}` and `app_updates` exist only in Firestore.
- **Deletion looks completely different on each side.** On the device the row
  is really gone, leaving a tombstone that holds nothing but an id; on the
  server the document remains with `deleted: true` and its ciphertext blanked.

For per-file detail, the date/enum conventions and the list of edge cases, read
`local/README.md` and `firebase/README.md`.
