# Access — the owner's allow-list

Two grants the owner hands out by address, from Firestore rather than from the
build: **`premium`** (in the app, and as a target of the pressure-alert cron)
and **`dev_settings`** (the Dev group in Settings). Field names are snake_case
per `docs/rules/DATA_AND_SYNC.md`; the Dart entity that carries them is not.

It replaced `PREMIUM_EMAIL` and `SHOW_DEV_SETTINGS`, two `--dart-define` keys
that lived in `env/<flavor>.json` and `functions/.env`. **The reason is the
turnaround**: granting the App Review account premium meant a new binary through
review, and the app's copy and the cron's copy of the same address were two
files that had to be edited together and could disagree.

## The shape, and why it is rows rather than a list

```
app_access/{email}          # document id IS the address, lower-cased
  premium: true             # premium in the app + a target of the cron
  dev_settings: true        # Settings shows its Dev group
```

**The address is the document id so a client can be given its own row and no
way to reach any other.** The rule is
`request.auth.token.email.lower() == email`. A single document holding two
arrays would be far easier to edit and impossible to read safely: a collection
matched on a *field* has to be readable as a whole to be readable at all, and
the whole is a list of real people's email addresses.

- **Absent means nothing granted**, which is the normal state for every address
  on earth. `AccessGrants.none` is what a missing document, a denied read, an
  anonymous session and a read still in flight all produce.
- **A flag is granted only by exactly `true`.** `"true"` typed into the console
  as a string is not a grant — see `premiumEmailsFrom` on the functions side,
  which is tested for it.
- **Both names are constants, and both are pinned by a test.** A `devSettings`
  typed by hand instead of `dev_settings` returns nothing at all: no error, no
  log, just a grant that never applies.
- **Written only from the Firebase console.** `allow write: if false`, for
  everyone. A client that could write its own row is precisely the client-side
  premium flag this project forbids.

## What reads it

| Reader | Provider / function | Effect |
|---|---|---|
| App gates | `hasAccessPremiumProvider` → `hasPremiumProvider` | Premium ahead of the entitlement |
| Settings | `showDevSettingsProvider` | The Dev group on a **prod** build |
| `pressureAlertJob` | `premiumEmailsFrom` + `getUserByEmail` | The account is pushed to |

- **`showDevSettingsProvider` is `!AppEnv.isProd || grants.devSettings`.** A dev
  flavour shows the group with no grant at all — that is what every build did
  before any flag existed, and a developer is usually not signed in. The
  allow-list is what adds the group to a **prod** build, which is how a
  TestFlight tester reaches the fixtures against real Firebase.
- **`_accessEmailProvider` exists so the read depends on the address, not on the
  auth stream.** `authUserProvider` emits twice on a normal launch — the
  restored session, then the same session again as data — and a provider
  watching it directly opened two Firestore listeners for one user.
- **An anonymous session never issues the read.** It carries no address, the
  rules would deny it, and the answer is `none` either way. That short-circuit
  is also why no widget test has to override `accessRepositoryProvider`: the
  repository is only built on the signed-in branch.
- **The cron resolves an address through Auth, not through a `users.email`
  query.** Firebase Auth normalises an address to lower case and Firestore `==`
  does not, so a `users` doc written `Review@BaroEase.app` is invisible to the
  only query the allow-list can build. Auth also answers for an account that
  has no `users` doc yet.

## Not the client-side premium flag the repo forbids

That rule is about state the running app can *write*. This is a server document
the client cannot write, matched against an address only Google or Apple
sign-in can put on the session — so an anonymous session never matches and
nothing on device changes the answer. Deliberately live in prod, unlike
`DevPremiumOverride`.

Adding an address: `docs/rules/PENDING_SETUP.md`.
