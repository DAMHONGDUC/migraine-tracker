# App config — the owner's Firestore control panel

**One document, `app_config/current`, holds every switch the owner controls.**

| Field | Type | What it does |
|---|---|---|
| `force_update` | map | `ios` / `android` published build; read on every launch |
| `premium_emails` | string[] | Premium in the app, and targets of the alert cron |
| `dev_mode_emails` | string[] | Settings shows its Dev group on a **prod** build |
| `blocked_emails` | string[] | Locked out: the block screen and nothing else |
| `error_view` | map | The owner's notice in front of the whole app |

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
and `error_view` through `ErrorViewMapper`, handing each back on its own
`AppConfig` field, so every switch on this page arrives on the same snapshot. Force update used to be its own feature over its
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
  "error_view": {"enable": false,
                 "title": "BaroEase is having trouble",
                 "subtitle_1": "We are repairing the connection to our servers.",
                 "subtitle_2": "Everything you have logged is safe on this device.",
                 "type": "warning"},
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
| `error_view` | shows nothing | `enable: true` **and** a non-empty `title` |

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
| App root | `remoteErrorViewProvider` → `RemoteErrorGate` | Replaces the whole app |
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
  and wave an unsupported build straight through. A later edit still arrives:
  `.future` resolves with the provider's newest value, and `check` runs again on
  every resume, so saving the console document and returning to the app is
  enough — `force_update_test.dart` pumps that round trip.
- **The check says why it decided, every time** (owner's report, 2026-09-21:
  "force is true but no dialog"). Six of `ForceUpdateDecision`'s seven answers
  are "carry on", the owner types the record by hand, and none of the six used
  to write a line — so a flag at the wrong level, a section dropped for a
  missing `store_link`, and a build that is simply not out of date were one
  symptom: nothing happens. `ForceUpdateController.check` logs `decision`
  beside every input that fed it, under `LogTagConstant.appUpdate`.

  | `decision` | What to change in `app_config/current` |
  |---|---|
  | `noPublishedBuild` | `force_update.<platform>` is missing, or was dropped for having no `store_link` or no `build_number` |
  | `notEnabled` | `enable_force_update` is not `true` **inside** `ios` / `android` — beside them it reads as absent |
  | `noStoreLink` | `store_link` is empty |
  | `installedIsNewer` | `build_name` is older than the installed one; the name settles it outright |
  | `buildNumberUnknown` | `build_number` is 0 or unreadable on one side |
  | `upToDate` | The record is fine — this build is not older than `build_name`/`build_number`. **The usual answer when testing the switch** |
  | `blocked` | The sheet goes up |

  `enableForceUpdate: true` logged next to `publishedSection: none` is the
  mistake the pair exists to catch: the flag parsed, the section did not.
- **The list sits above the entitlement in `hasPremiumProvider`.** It returns
  `true` early, ahead of the Dev override and RevenueCat, so a reviewer signed
  in as that address is premium in a prod flavour too.
- **The cron reads the same list.** Pressure alerts *are* a premium feature, so
  it takes `premium_emails` off this document rather than keeping a copy — the
  app and the cron cannot disagree about who is premium by address.
- **Every gate here is a layer in the tree, not a pushed route — force update
  included, since 2026-09-21.** A layer clears the moment the flag does and
  cannot get out of step with it the way a route that has to be popped can.
  `BlockedAccountGate` sits *inside* `ForceUpdateWrapper`, so a blocked user on
  an unsupported build is told to update first: one of the two has to win, and
  the store link helps either way.
  - **Force update was the exception, and it was the bug** (owner's report:
    "it shows, then it is gone once the dashboard opens"). The sheet was pushed
    on `rootNavigatorKeyProvider`, which is **go_router's own navigator**: it
    appeared over the splash and was thrown away the moment the splash called
    `context.go('/dashboard')`, because that rebuilds the stack it was sitting
    in. The wrapper had already set `_sheetShown`, so nothing put it back and
    the user reached the dashboard on a build the owner had blocked. The block
    lasted exactly until the app finished launching.
  - **It is still a sheet, not a screen** (owner's rule, 2026-09-21: it must
    cover the app, and Update must be the only thing the user can touch). So
    `ForceUpdateSheet` draws its own `Stack` over the app: `SdThemeV2.barrier`,
    the `surfaceModal` panel with r22 top corners capped at
    `SdBreakpointV2.contentMaxWidth`, and no drag handle — every part of the
    `showSdBottomSheetV2(dismissible: false)` it replaces, minus the route.
    The `ModalBarrier` is what makes it a block: it takes every pointer, so the
    app stays visible underneath and entirely out of reach.
    `force_update_test.dart` navigates to the dashboard and taps the target
    behind the barrier; both leave the sheet up.
  - **A failed store launch is said INSIDE the sheet, never in a snackbar.**
    `SdSnackBarUtilsV2` draws into the root overlay, which lives inside the
    navigator — below this layer — so a message raised here would be painted
    behind the barrier that raised it. The sheet is the only visible surface,
    so it is the only place a message can go.
- **Signing out is the way out, and the screen says so.** Membership is by
  address, so an anonymous session is on no list and the app comes back.
  **It is the normal sign-out** (`AccountController.signOut`, owner's rule,
  2026-09-24): the account has been syncing, so the device's records are its
  own — they are pushed, the device emptied, and only then signed out. A bare
  sign-out used to leave them for whoever signed in next. A record still owed
  keeps the session, exactly as on the Account screen.
- **The block screen shows its messages on itself, never in a snackbar.** It
  renders instead of the app, navigator included, so `SdSnackBarUtilsV2` had no
  overlay to draw into: a failed sign-out or support email said nothing at all.
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

## `error_view` — the owner's notice

One map, parsed by `ErrorViewMapper`, that replaces the whole app with a screen
in the owner's words. For an outage, a migration, an incident: the things that
are true for everybody and that no build can fix from the store.

| Field | Type | Note |
|---|---|---|
| `enable` | bool | **Explicit `true` only.** `"true"`, `1` and absent are all off |
| `title` | string | The headline. Empty means the notice is dropped |
| `subtitle_1` / `subtitle_2` | string | Optional body lines; only the ones with text are drawn |
| `type` | string | `warning` or `error` — the glyph and its colour, nothing else |

- **Two independent refusals, and both matter.** A notice that could be
  switched on by a typo takes the app away by typo, so `enable` must be
  literally `true`; and a notice with a blank headline replaces a working app
  with a screen that says nothing, which is strictly worse than not showing it.
- **The entity existing *is* the switch.** `AppConfig.errorView` is null for
  off, absent, malformed and empty alike — the shape `forceUpdate` already
  uses, so "should this show" is never asked in two places that could disagree.
- **`type` is the one field where an unreadable value reads loud, not quiet.**
  Everywhere else on this document a malformed field grants nothing, because
  every other field hands out a privilege or takes the app away. Here the
  notice is already being shown on purpose, so a typo must not silently
  downgrade an outage to a warning: anything unrecognised is `error`.
- **The copy is not localized, and cannot be.** Every other string in the app
  goes through the ARB files; these three are typed into the console mid-incident
  in whatever language the owner writes, and there is no key to translate ahead
  of an incident nobody has had yet.
- **`RemoteErrorGate` sits inside `ForceUpdateWrapper` and outside
  `BlockedAccountGate`.** Inside force update for the reason the block is
  inside it: one of them has to win and the store link helps either way.
  Outside the block because a notice is addressed to everybody and the block to
  one account — telling a blocked user the backend is down is the more useful
  of the two sentences.
- **It is not keyed on an address**, unlike every other gate here, so it reads
  the same for an anonymous session. An outage is not a list somebody is on.
- **`RemoteErrorView` is not `SdErrorViewV2`.** That widget draws one body line
  plus a `detail` row meant for a raw failure outside production; this one
  draws two body lines the owner wrote for the user, and colours its glyph by
  severity. Bending `detail` into a second subtitle would leave the next reader
  of either file believing something untrue about the other.

## Not the client-side premium flag the repo forbids

That rule is about state the running app can *write*. This is a server document
the client cannot write, matched against an address only Google or Apple
sign-in can put on the session — so an anonymous session never matches and
nothing on device changes the answer. Deliberately live in prod, unlike
`DevPremiumOverride`.

Filling the document in: `docs/rules/PENDING_SETUP.md`. A full sample:
`sample_json/firebase/app_config.json`.
