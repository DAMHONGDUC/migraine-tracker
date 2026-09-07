# Cloud Functions and the force-update gate

Hard rules 9 and 10, plus what Cloud Functions must do.

9. **Force update fails open.** The launch check (`app_config`) reads the `force_update` field off the same `appConfigProvider` listener every other switch comes from — never a second read of its own — on the public, read-only `app_config/current` document and blocks ONLY on an explicit `enable_force_update` against a strictly newer `build_number`. Offline, a missing record, an unreadable field or a malformed link must let the user in — someone mid-attack has to reach the log button. Compare `build_name` first (via `VersionUtils`, segment by segment as numbers — never as strings, `"1.10.0" < "1.9.0"` is true for a string), then `build_number` as the tiebreaker for two builds of the same version.
10. Cloud Functions: group users by geohash before calling weather APIs — one forecast call per cell, never per user. Dedupe alerts: max 3 pushes per user per day, at least 8h apart, and never twice for the same pressure event. A push landing in the user's local night (22:00-07:00) is sent without a sound — the front is still worth knowing about at 03:00, being woken for it is not.
- Cloud Functions: idempotent, log with structured JSON, fail loud on weather API errors (retry with backoff), never silently skip a user cohort.
