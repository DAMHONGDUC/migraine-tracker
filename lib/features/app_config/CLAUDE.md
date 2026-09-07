# App config — the owner's Firestore control panel

**One document, `app_config/current`, holds every switch the owner controls.**

| Field | Type | What it does |
|---|---|---|
| `premium_enabled` | bool | False turns premium off for **everybody at once** |
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
not. **Every name lives once, in `AppConfigSchema`** — two repositories read
this document, and a field spelled in two places is a field one of them will one
day spell wrong, silently, because an unknown key reads as absent rather than as
an error.

**Force update lives here too**, in `data/repositories/app_update_mapper.dart`
and the widgets beside `BlockedAccountGate`. It was its own `app_update` feature
while it read its own collection; reading one field of this document does not
make it a second feature, and the split had the schema being imported across a
feature boundary to keep one field name honest.

## The shape

```json
{
  "premium_enabled": true,
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

## The two halves default in opposite directions, on purpose

| | Absent, denied, or still loading | Set by |
|---|---|---|
| Address lists | nobody listed, **nobody blocked** | the address being on the list |
| `premium_enabled` | premium **on** | exactly `false` |
| `force_update` | blocks nobody | `enable_force_update: true` |

**A list is something an address has to be put on; a kill switch is something
the owner has to actively throw.** Defaulting `premium_enabled` to false would
mean an offline first launch, an install ahead of the document existing, or one
denied read takes premium away from somebody who paid for it. `"false"` typed
into the console as a string is not a throw.

`blocked_emails` follows the *list* direction: a read that has not landed must
never lock somebody out of an app whose data is on their own device.

**Both sides of every comparison are trimmed and lower-cased** (`AppConfig`).
Firebase Auth stores an address lower-cased and the owner types the list by
hand, so `Review@BaroEase.app` in the console has to match
`review@baroease.app` on the session — comparing raw would fail silently,
granting nothing and looking like a typo nobody made.

## What reads it

| Reader | Provider / function | Effect |
|---|---|---|
| App gates | `premiumEnabledProvider` → `hasPremiumProvider` | **Closes every premium gate**, ahead of everything |
| App gates | `hasGrantedPremiumProvider` → `hasPremiumProvider` | Premium ahead of the entitlement |
| App root | `isAccountBlockedProvider` → `BlockedAccountGate` | Replaces the whole app |
| Settings | `showDevSettingsProvider` | The Dev group on a **prod** build |
| Launch check | `FirestoreAppUpdateRepository.latest()` | Reads `force_update`; hard rule 9 fails open |
| `pressureAlertJob` | `premiumEnabledFrom` | An off switch ends the pass before any push |
| `pressureAlertJob` | `premiumEmailsFrom` + `getUserByEmail` | The accounts pushed to |

- **One listener, not one per gate.** Every provider above reads the same
  `appConfigProvider` stream; `app_config_test.dart` asserts `watchCalls == 1`
  after all four gates have been read.
- **The kill switch sits above the list in `hasPremiumProvider`, not below
  it.** The list returns `true` early, and the Dev override returns before the
  entitlement — a switch placed anywhere else would be one two surfaces could
  talk their way past.
- **The cron honours it too.** Pressure alerts *are* a premium feature, and
  unlike a hidden screen a push cannot be taken back once it lands. It reads
  the document once for both the switch and the list, so it sees exactly what
  the app sees.
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
