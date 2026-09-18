# App config — the owner's Firestore control panel

**One document, `app_config/current`, holds every switch the owner controls.**

| Field | Type | What it does |
|---|---|---|
| `force_update` | map | `ios` / `android` published build; read on every launch |
| `premium_emails` | string[] | Premium in the app, and targets of the alert cron |
| `dev_mode_emails` | string[] | Settings shows its Dev group on a **prod** build |
| `blocked_emails` | string[] | Locked out: the block screen and nothing else |

It replaced `PREMIUM_EMAIL` and `SHOW_DEV_SETTINGS` (two `--dart-define` keys in
`env/<flavor>.json` and `functions/.env`), the `app_access` collection, and the
`app_updates` one. **The reason is the turnaround**: granting the App Review
account premium meant a new binary through review, and the app's copy and the
cron's copy of the same address were two files that could disagree.

Field names are snake_case per `docs/rules/DATA_AND_SYNC.md`; the Dart entity is
not. **Every name lives once, in `AppConfigSchema`**, and a field spelled in two
places is a field one of them will one day spell wrong, silently, because an
unknown key reads as absent rather than as an error.

**One document, one listener, one entity.** `FirestoreAppConfigRepository` is
the app's only read of it: it parses `force_update` through `AppUpdateMapper`
and hands it back on `AppConfig.forceUpdate`, so every switch on this page
arrives on the same snapshot. Force update used to be its own feature over its
own collection, then its own repository doing a second `get` of this same
document on every launch and every resume — which was a second reader to keep
pointing at the right document id, a second thing to be denied on its own, and a
second read to pay for.

**A failed read emits `AppConfig.empty` rather than nothing.** The stream logs
the error and pushes the fallback (`StreamTransformer`, not `handleError`),
because `ForceUpdateController.check` awaits the first value — a stream that
logs and ends would leave a cold start waiting for good.

## The shape

```json
{
  "force_update": {
    "ios":     {"store_link": "https://apps.apple.com/app/id0000000000",
                "build_name": "1.4.0", "build_number": 41,
                "enable_force_update": false},
    "android": {"store_link": "https://play.google.com/store/apps/details?id=app.dd.migraine.tracker",
                "build_name": "1.4.0", "build_number": 41,
                "enable_force_update": false}
  },
  "premium_emails":  ["review@baroease.app", "owner@baroease.app"],
  "dev_mode_emails": ["owner@baroease.app"],
  "blocked_emails":  ["banned@example.com"]
}
```

## The address lists are public. That is the trade.

**The document is world-readable**, because the force-update check runs before
any sign-in and the app is fully usable anonymously — a switch only signed-in
installs could read would miss almost every user it exists for. **Firestore
rules cannot hide a field**, so `premium_emails`, `dev_mode_emails` and
`blocked_emails` are readable by anyone who installs the app.

The owner chose this deliberately: one document to edit, in exchange for the
lists not being private. The alternative — and what `app_access` did — is one
document per address, keyed on the address, so the rules can hand a client its
own row and nothing else. **Do not put anything on this document that is worse
to publish than an address already is**, and if the lists ever have to become
private, that is the shape to go back to.

`current` is the only document, and the rules match only it: a `list` over the
collection has no rule at all, so the path cannot be walked for anything added
later. **The id lives in three places** — `AppConfigSchema.documentId`,
`APP_CONFIG_DOCUMENT` in `functions/`, and the `match` in `firestore.rules` —
and all three move together or the read is denied.

- **Written only from the Firebase console.** `allow write: if false`, for
  everyone. A client that could write this document could grant itself premium
  — the client-side premium flag this project forbids — or forge a
  force-update record and lock everybody out.

## Absent, denied and still loading all grant and deny nothing

| | Absent, denied, or still loading | Set by |
|---|---|---|
| Address lists | nobody listed, **nobody blocked** | the address being on the list |
| `force_update` | blocks nobody | `enable_force_update: true` |

**Every field is something an address has to be put on, or a record the owner
has to write.** An offline first launch, an install ahead of the document
existing, or one denied read must leave the app exactly as it was — and
`blocked_emails` most of all: a read that has not landed must never lock
somebody out of an app whose data is on their own device.

**Both sides of every comparison are trimmed and lower-cased** (`AppConfig`).
Firebase Auth stores an address lower-cased and the owner types the list by
hand, so `Review@BaroEase.app` in the console has to match
`review@baroease.app` on the session — comparing raw would fail silently,
granting nothing and looking like a typo nobody made.

## What reads it

| Reader | Provider / function | Effect |
|---|---|---|
| App gates | `hasGrantedPremiumProvider` → `hasPremiumProvider` | Premium ahead of the entitlement |
| App root | `isAccountBlockedProvider` → `BlockedAccountGate` | Replaces the whole app |
| Settings | `showDevSettingsProvider` | The Dev group on a **prod** build |
| Launch check | `forceUpdateControllerProvider` → `ForceUpdateWrapper` | Reads `AppConfig.forceUpdate` off the same stream; hard rule 9 fails open |
| `pressureAlertJob` | `premiumEmailsFrom` + `getUserByEmail` | The accounts pushed to |

- **One listener, not one per gate — force update included.** Every reader
  above comes off the same `appConfigProvider` stream; `app_config_test.dart`
  asserts `watchCalls == 1` after all three gates have been read, and
  `force_update_test.dart` asserts the same after a launch that ran the update
  check.
- **The check awaits the first snapshot, it does not read the current one.** On
  a cold start the document has usually not landed by the time
  `ForceUpdateWrapper` mounts, and reading there would answer `AppConfig.empty`
  and wave an unsupported build straight through.
- **The list sits above the entitlement in `hasPremiumProvider`.** It returns
  `true` early, ahead of the Dev override and RevenueCat, so a reviewer signed
  in as that address is premium in a prod flavour too.
- **The cron reads the same list.** Pressure alerts *are* a premium feature, so
  it takes `premium_emails` off this document rather than keeping a copy — the
  app and the cron cannot disagree about who is premium by address.
- **`BlockedAccountGate` is a layer in the tree, not a pushed route** — which is
  how force update does it. The block clears the moment the user signs out, and
  a plain `if` cannot get out of step with the flag the way a route that has to
  be popped can. It sits *inside* `ForceUpdateWrapper`, so a blocked user on an
  unsupported build is told to update first: one of the two has to win, and the
  store link helps either way.
- **Signing out is the way out, and the screen says so.** Membership is by
  address, so an anonymous session is on no list and the app comes back — with
  every log still on the device, because none of it ever left.
- **`showDevSettingsProvider` is `!AppEnv.isProd || hasDevMode(email)`.** A dev
  flavour shows the group with nobody listed — that is what every build did
  before any flag existed, and a developer is usually not signed in. The list is
  what adds the group to a **prod** build, which is how a TestFlight tester
  reaches the fixtures against real Firebase.
- **`_configEmailProvider` exists so the gates rebuild on the address, not on
  the auth stream.** `authUserProvider` emits twice on a normal launch — the
  restored session, then the same session again as data — and a provider
  watching it directly rebuilt every gate twice for one user.
- **The read has no signed-in short-circuit, and must not get one.** That is why
  `appConfigRepositoryProvider` is overridden in `pump_app.dart` for every
  widget test: without it, any tree that gates on premium opens a real Firestore
  listener.
- **The cron resolves an address through Auth, not through a `users.email`
  query.** Firebase Auth normalises an address to lower case and Firestore `==`
  does not, so a `users` doc written `Review@BaroEase.app` is invisible to the
  only query that could be built. Auth also answers for an account that has no
  `users` doc yet.
- **A malformed field grants nothing rather than throwing.** The lists are typed
  by hand: anything that is not an array of strings reads as empty, and a
  non-string entry is dropped.

## Not the client-side premium flag the repo forbids

That rule is about state the running app can *write*. This is a server document
the client cannot write, matched against an address only Google or Apple
sign-in can put on the session — so an anonymous session never matches and
nothing on device changes the answer. Deliberately live in prod, unlike
`DevPremiumOverride`.

Filling the document in: `docs/rules/PENDING_SETUP.md`. A full sample:
`sample_json/firebase/app_config.json`.
