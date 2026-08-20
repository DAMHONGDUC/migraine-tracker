# WeatherKit — setup and migration guide

Replacing Open-Meteo with Apple WeatherKit, everywhere: one provider for the
whole app, backend included (`docs/rules/TECH_STACK.md`). Work top to bottom —
each step depends on the one before, and steps 1–4 are credentials that must
exist before any code can be tested at all.

**Why the app has no weather API of its own.** WeatherKit's REST API is
authenticated with an ES256 JWT signed by a private `.p8`. A key that ships in a
binary is a key that is extracted, so the app never signs anything: it asks the
backend, and the backend asks Apple.

## Step 1 — A Key with WeatherKit enabled

Apple Developer → Certificates, Identifiers & Profiles → **Keys** → ＋, name it,
tick **WeatherKit**, register, download. You get `AuthKey_XXXXXXXXXX.p8` and a
**Key ID** (the JWT's `kid`).

**Downloadable once** — lose it and the key must be revoked and remade. **It is
not the APNs key**: different key, different capability, identical-looking
download.

## Step 2 — A Services ID

Identifiers → **Services IDs** → ＋. Any readable description; a reverse-DNS
identifier, e.g. `app.dd.migraine.tracker.weather`.

This becomes the JWT's `sub`. **The app's Bundle ID will not work in its place** —
a Services ID is a distinct identifier type, and the bundle id returns 401 with
nothing explaining why.

## Step 3 — The Team ID

Apple Developer → Membership. Ten characters. It is the JWT's `iss` and half of
the `id` header claim (`{TeamID}.{ServicesID}`).

## Step 4 — The `.p8` into Secret Manager

Never in the repo, never in `env/` — a `--dart-define` is a build-time value, not
a secret store (hard rule 13).

```bash
gcloud secrets create WEATHERKIT_PRIVATE_KEY --data-file=AuthKey_XXXXXXXXXX.p8
```

Grant the functions runtime access, then declare it with `defineSecret` from
`firebase-functions/params`.

**The other three go in `functions/.env`.** The Key ID, Team ID and Services ID
name a key, a team and a service and sign nothing, so they are `defineString`
params the Firebase CLI reads at deploy time:

```
WEATHERKIT_KEY_ID=ABC123XYZ
WEATHERKIT_TEAM_ID=A1B2C3D4E5
WEATHERKIT_SERVICE_ID=app.dd.migraine.tracker.weather
```

`melos run set-up` copies `functions/.env.example` into place; the file itself is
gitignored, because the values are per-developer.

**Leaving it empty fails the deploy rather than prompting:**

> In non-interactive mode but have no value for the following environment
> variables: WEATHERKIT_KEY_ID, WEATHERKIT_TEAM_ID, WEATHERKIT_SERVICE_ID

That reads like a CLI bug and is not one — melos pipes the deploy script's
stdout, so the CLI correctly decides it cannot ask a human. Fill the file;
running `firebase deploy` by hand in a real terminal is the workaround.

## Step 5 — The WeatherKit client

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

Cache the token for its lifetime — signing per request is wasted CPU on every
cron run, and the cron is the only caller.

**The request:**

```
GET https://weatherkit.apple.com/api/v1/weather/en/{lat}/{lon}?dataSets=forecastHourly
Authorization: Bearer <jwt>
```

Hourly pressure arrives as `forecastHourly.hours[].pressure` in
**hPa/millibars** — the same unit Open-Meteo returned and the same unit
`DropForecast` and the alert threshold already use, so no conversion and no
change to the pressure maths.

**Keep `fetchHourlyPressure`'s existing signature.** The geohash grouping, the
dedupe window and the alert maths sit on top of it and none should be touched by
a provider swap. Keep the retry-with-backoff too — weather API errors fail loud,
never skip a cohort.

## Step 6 — Swap the call site

- `functions/src/index.ts:23` — import from `./weather/weatherKit`
- Delete `functions/src/weather/openMeteo.ts` and `test/openMeteo.test.ts`
- Port the tests to the new parser: malformed body, HTTP error, retry exhaustion.
  Same cases, so port rather than start over.

```bash
cd functions && npm run build && npm test
```

## Step 7 — Point the app at the backend

The app currently calls a weather API directly through
`weatherRepositoryProvider`. After this it must call none: add a callable
returning the forecast the app needs, and implement `WeatherRepository` against
it. Everything already depends on that interface, so this is a new data source,
not a rewrite. Hard rule 4 still holds — logging must work offline, and a failed
weather read is "no weather", never an error.

## Step 8 — Rate-limit whatever the app can reach

**Quota is 500k calls/month for the whole team, and this change concentrates
it.** Calls used to come from users' own devices; now every one lands on our key.
The cron is bounded by design (one call per geohash cell), but the callable from
step 7 is reachable by anyone with the app, so it needs its own limit — without
one, a single caller can burn the month for everybody.

## Step 9 — Attribution

**A shipping requirement, not a nicety.** Apple requires the Weather trademark
and a link to its legal page wherever weather data is shown: the dashboard's
pressure reading, the 48-hour forecast chart, the pressure detail screen and the
home screen widget.

`https://weatherkit.apple.com/legal-attribution.html`

## Step 10 — Deploy and verify

```bash
melos run deploy-firebase-dev functions
```

Verify against the cron's own path rather than a simpler one:

- a forecast returns for a known cell, with plausible hPa values;
- a bad key fails loudly in the logs rather than silently skipping users;
- the alert still fires on **delta** (≥5 hPa drop in 24h), not absolute values.

## What blocks what

**1–4 are credentials** and block everything: until they exist there is nothing
to sign with, so the code cannot be run once. **5–6 are the backend** and can be
written before the credentials arrive, just not verified. **7–9 are the app**,
and step 9 blocks App Store review rather than a build.
