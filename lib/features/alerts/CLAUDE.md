# Pressure alerts

Hard rule 7. The controls themselves live on Insights' pressure card.

7. **Pressure math triggers on delta**, not absolute values: by default a ≥5 hPa
   drop within the 24h forecast. The threshold is user-tunable and stored
   per-user.

- **The server never pushes to an anonymous session, and that is a chain, not a
  check.** Owner's rule. Premium requires an account (`PurchaseIdentity` binds a
  purchase only when `isSignedIn`), and alerts require premium (the cron reads
  `users` where `premium == true`, plus the allow-listed accounts below, which
  only Google or Apple sign-in can produce), so an anonymous user cannot reach
  the push path at all. Anything that pushes — the cron, `sendTestPush` — may
  assume an account, and anything that appears to serve an anonymous device a
  notification is a bug.
- **The cron targets the `app_access` allow-list as well.** `premium` is written
  only by the RevenueCat webhook, so an allow-listed account never carries it —
  and a reviewer the app grants premium would pass every gate and still never
  get an alert, which is the one surface disagreeing with the rest.
  `pressureAlertJob` adds those accounts and dedupes by uid.
  - The addresses come from `app_access` where `premium == true`, the same
    documents the app reads (`lib/features/access/CLAUDE.md`). Empty, nothing
    extra is fetched.
  - **Resolved through Auth, not through a `users.email` query.** Auth
    normalises an address to lower case and Firestore `==` does not, so a doc
    written `Review@BaroEase.app` is invisible to the only query the list can
    build. Auth also answers for an account with no `users` doc yet, where the
    absent doc simply means no device has registered.
- **Registration refuses a signed-out or anonymous device outright.** It used to
  write a token for one and lean on `premium == false` to stop the cron
  targeting it, and it called `signInAnonymously` itself. Both are gone:
  `FirebaseAlertRegistrationRepository` throws
  `AlertRegistrationError.accountRequired`, and the switch opens the paywall
  rather than toggling.
  - This is about **alerts only**. The app still holds an anonymous session for
    weather (hard rule 1), so "has a uid" and "may register for alerts" are
    different questions.

## Every run is written down

**`pressure_alert_runs` holds one document per `pressureAlertJob` run**, id =
the run's start instant in ISO, so the console sorts by id alone. Nobody watches
a cron happen, and by the time a user reports "I never got an alert" the Cloud
Logging retention window may have closed over the run that should have sent it.

| Field | Reads |
|---|---|
| `status` | `ok`, `partial` (finished with cells it could not fetch), `failed` (threw) |
| `users` / `cells` / `pushes_sent` | Users considered, WeatherKit calls spent, pushes actually sent |
| `failed_cells` / `failed_cell_count` | A sample capped at 50; the count is always the true total |
| `max_drop_hpa` | The worst drop seen anywhere that run; null when no cell returned a reading |
| `cell_drops` / `cell_drop_count` | Per cell: `current_hpa`, `drop_hpa`, `event_id`. Biggest drops first, capped at 50 |
| `started_at` / `finished_at` / `duration_ms` | Where the 540s timeout is going |
| `error` | Null on any run that finished, whatever its status |

Fields are snake_case (`docs/rules/DATA_AND_SYNC.md`) and TypeScript is not, so
`alertRunDocument` does the rename in one place and a test pins the key set.

- **The readings are kept, not just the counts.** `pushes_sent: 0` is the
  ordinary result, and without the pressure behind it the document cannot say
  whether that was a flat forecast, a drop under everyone's threshold or dedupe.
  A cell missing from `cell_drops` was either in `failed_cells` or came back with
  no sample near the run's own hour.
- **The write sits outside the try/catch that guards the run.** A run that threw
  is the one the history most needs to hold, so `runAlertPass` is a separate
  function and the record is built from whatever came back — result or throw.
- **The write is best-effort and the run still fails loud.** A failed history
  write logs and is dropped; the original error is re-thrown afterwards, so the
  scheduler still sees the run as failed.
- **Denied to every client** (`firestore.rules`): it names uids and geohash
  cells and exists for the owner's console. Bound it with a Firestore TTL policy
  on `startedAt` if it ever grows.
