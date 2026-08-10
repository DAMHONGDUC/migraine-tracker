# WeatherKit — setup and migration guide

Replacing Open-Meteo with Apple WeatherKit, everywhere. One provider for the
whole app, backend included (CLAUDE.md's tech-stack rule). Work top to bottom:
each step depends on the one before it, and steps 1–4 are credentials that must
exist before any code can be tested at all.

**Why the app has no weather API of its own.** WeatherKit's REST API is
authenticated with an ES256 JWT signed by a private `.p8`. A key that ships in
a binary is a key that is extracted, so the app never signs anything — it asks
the backend, and the backend asks Apple.

---

## Step 1 — Create a Key with WeatherKit enabled

Apple Developer → Certificates, Identifiers & Profiles → **Keys** → ＋

- Name it (e.g. `BaroEase WeatherKit`)
- Tick **WeatherKit**
- Continue → Register → **Download**

You get a `AuthKey_XXXXXXXXXX.p8` and a **Key ID**.

- **Downloadable once.** Lose it and the key must be revoked and remade.
- **This is not the APNs key.** Different key, different capability, even
  though the download looks identical.
- Record the **Key ID** — it becomes the JWT's `kid` header.

## Step 2 — Register a Services ID

Apple Developer → Identifiers → **Services IDs** → ＋

- Description: anything readable
- Identifier: reverse-DNS, e.g. `app.dd.migraine.tracker.weather`

This becomes the JWT's `sub`. **The app's Bundle ID will not work in its
place** — a Services ID is a distinct identifier type, and using the bundle id
returns 401 with nothing explaining why.

## Step 3 — Note the Team ID

Apple Developer → Membership. A 10-character string.

It is the JWT's `iss`, and half of the `id` header claim
(`{TeamID}.{ServicesID}`).

## Step 4 — Put the `.p8` in Secret Manager

Never in the repo, never in `env/` — a `--dart-define` is a build-time value,
not a secret store (hard rule 13).

```bash
gcloud secrets create WEATHERKIT_PRIVATE_KEY --data-file=AuthKey_XXXXXXXXXX.p8
```

The Key ID, Team ID and Services ID are identifiers rather than secrets, so
they can be plain environment config — but keep them beside the secret so all
four move together.

Grant the functions runtime access, then declare it with `defineSecret` from
`firebase-functions/params` so the deployed function can read it.

## Step 5 — Write the WeatherKit client

New file: `functions/src/weather/weatherKit.ts`.

**The JWT**, signed ES256:

| Field | Value |
|---|---|
| header `alg` | `ES256` |
| header `kid` | Key ID from step 1 |
| header `id` | `{TeamID}.{ServicesID}` |
| payload `iss` | Team ID |
| payload `sub` | Services ID |
| payload `iat` / `exp` | now / now + 1 hour |

Cache the token for its lifetime. Signing per request is wasted CPU on every
cron run, and the cron is the only caller.

**The request:**

```
GET https://weatherkit.apple.com/api/v1/weather/en/{lat}/{lon}?dataSets=forecastHourly
Authorization: Bearer <jwt>
```

Hourly pressure comes back as `forecastHourly.hours[].pressure`, in
**hPa/millibars** — the same unit Open-Meteo returned and the same unit
`DropForecast` and the alert threshold are already in, so no conversion and no
change to the pressure maths.

**Keep `fetchHourlyPressure`'s existing signature.** The geohash grouping, the
dedupe window and the alert maths all sit on top of it and none of them should
be touched by a provider swap. Keep the retry-with-backoff behaviour too —
CLAUDE.md requires failing loud on weather API errors, never skipping a cohort.

## Step 6 — Swap the call site

- `functions/src/index.ts:23` — import from `./weather/weatherKit`
- Delete `functions/src/weather/openMeteo.ts` and `test/openMeteo.test.ts`
- Write the equivalent tests against the new parser: malformed body, HTTP
  error, retry exhaustion. These are the same cases, so port them rather than
  starting over.

```bash
cd functions && npm run build && npm test
```

## Step 7 — Point the app at the backend

The app currently calls a weather API directly through
`weatherRepositoryProvider`. After this it must not call any weather API at
all: add a callable that returns the forecast the app needs, and implement
`WeatherRepository` against it.

Everything in the app already depends on the `WeatherRepository` interface, so
this is a new data source, not a rewrite. Hard rule 4 still holds — logging an
attack must work fully offline, and a failed weather read is "no weather",
never an error.

## Step 8 — Rate-limit whatever the app can reach

**Quota is 500k calls/month for the whole team, and this change concentrates
it.** Calls used to come from users' own devices; now every one lands on our
key. The cron is bounded by design — one call per geohash cell, never per user
— but the callable added in step 7 is reachable by anyone with the app, so it
needs a limit of its own. Without one, a single caller can burn the month for
everybody.

## Step 9 — Add the attribution

**A shipping requirement, not a nicety.** Apple requires the Weather trademark
and a link to its legal attribution page wherever weather data is shown. That
means every surface: the dashboard's pressure reading, the 48-hour forecast
chart, the pressure detail screen, and the home screen widget.

Attribution URL: `https://weatherkit.apple.com/legal-attribution.html`

## Step 10 — Deploy and verify

```bash
melos run deploy-firebase functions
```

Verify against the cron's own path rather than a simpler one:

- A forecast is returned for a known cell, with plausible hPa values
- A bad key fails loudly in the logs rather than silently skipping users
- The alert still fires on **delta** (≥5 hPa drop in 24h), not absolute values

---

## Order, and what blocks what

Steps **1–4 are credentials** and block everything: until they exist there is
nothing to sign with, so the code cannot be run even once.

Steps **5–6 are the backend**, and can be written before the credentials
arrive — they just cannot be verified.

Steps **7–9 are the app**, and step 9 is the one that blocks App Store review
rather than blocking a build.
