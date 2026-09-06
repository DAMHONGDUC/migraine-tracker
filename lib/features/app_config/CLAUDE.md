# App config — the owner's Firestore control panel

One collection, `app_config`, holding two kinds of document:

| Document | Holds | Applies to | Who can read it |
|---|---|---|---|
| `app` | `enable_premium`, `force_update` | every install | anyone, signed in or not |
| `{email}` | `premium`, `dev_settings`, `blocked` | that one address | only that address |

It replaced `PREMIUM_EMAIL` and `SHOW_DEV_SETTINGS` (two `--dart-define` keys in
`env/<flavor>.json` and `functions/.env`) and the `app_updates` collection.
**The reason is the turnaround**: granting the App Review account premium meant a
new binary through review, and the app's copy and the cron's copy of the same
address were two files that had to be edited together and could disagree.

Field names are snake_case per `docs/rules/DATA_AND_SYNC.md`; the Dart entities
that carry them are not. **Every name lives once, in `AppConfigSchema`** —
`app_update` reads `force_update` out of the same document, and a field two
features spell separately is a field one of them will one day spell wrong,
silently, because an unknown key reads as absent rather than as an error.

## The shape

```
app_config/app                    # world-readable, one fixed id
  enable_premium: false           # premium does not exist in this build, for anyone
  force_update:
    ios:     {store_link, build_name, build_number, enable_force_update}
    android: {store_link, build_name, build_number, enable_force_update}

app_config/{email}                # document id IS the address, lower-cased
  premium: true                   # premium in the app + a target of the cron
  dev_settings: true              # Settings shows its Dev group
  blocked: true                   # the address is locked out of the app
```

## Why two documents and not one

**Firestore rules cannot hide a field.** The update check runs before any
sign-in, so the document it reads has to be world-readable — and the app is
fully usable anonymously, so the premium kill switch has to reach installs with
no session at all. Put the addresses on that same document, as arrays, and every
person who installs the app can read the owner's list of real people.

So: **anything global goes on `app`, anything about a person goes in that
person's own row.** The rule for a row is
`request.auth.token.email.lower() == email`, which hands a client its own row
and no way to reach another. A collection matched on a *field* would have to be
readable as a whole to be readable at all, and the whole is that same list.

**`app` is safe as a fixed id because no sign-in produces it as an address.**
Its own rule block grants the `get`, and rules are OR-ed, so the `{email}` block
denying it changes nothing. What neither block allows is a `list`: a query has
no single document to evaluate, so the collection as a whole stays unreadable.

- **Written only from the Firebase console.** `allow write: if false`, for
  everyone. A client that could write its own row is precisely the client-side
  premium flag this project forbids, and a client that could write `app` could
  forge a force-update record and lock everybody out.

## The defaults are opposites, on purpose

| | Absent, denied, or still loading | Set by |
|---|---|---|
| Row grants (`AppConfigGrants.none`) | nothing granted, **not blocked** | exactly `true` |
| `enable_premium` (`AppConfigFlags.allOn`) | premium **on** | exactly `false` |
| `force_update` | blocks nobody | `enable_force_update: true` |

**A grant is something an address has to be given; a kill switch is something
the owner has to actively throw.** Defaulting `enable_premium` off would mean an
offline first launch, an install ahead of the document existing, or one denied
read takes premium away from somebody who paid for it. `"false"` typed into the
console as a string is not a throw, the same way `"true"` is not a grant.

`blocked` follows the *grant* direction, not the switch direction: a read that
has not landed must never lock somebody out of an app whose data is on their own
device.

## What reads it

| Reader | Provider / function | Effect |
|---|---|---|
| App gates | `premiumEnabledProvider` → `hasPremiumProvider` | **Closes every premium gate**, ahead of everything |
| App gates | `hasGrantedPremiumProvider` → `hasPremiumProvider` | Premium ahead of the entitlement |
| App root | `isAccountBlockedProvider` → `BlockedAccountGate` | Replaces the whole app |
| Settings | `showDevSettingsProvider` | The Dev group on a **prod** build |
| Launch check | `FirestoreAppUpdateRepository.latest()` | Reads `force_update`; hard rule 9 fails open |
| `pressureAlertJob` | `premiumEnabledFrom` | An off switch ends the pass before any push |
| `pressureAlertJob` | `premiumEmailsFrom` + `getUserByEmail` | The account is pushed to |

- **The kill switch sits above the allow-list in `hasPremiumProvider`, not
  below it.** The allow-list returns `true` early, and the Dev override returns
  before the entitlement — a switch placed anywhere else would be one two
  surfaces could talk their way past.
- **The cron honours it too.** Pressure alerts *are* a premium feature, and
  unlike a hidden screen a push cannot be taken back once it lands.
- **`BlockedAccountGate` is a layer in the tree, not a pushed route** — which is
  how force update does it. The block clears the moment the user signs out, and
  a plain `if` cannot get out of step with the flag the way a route that has to
  be popped can. It sits *inside* `ForceUpdateWrapper`, so a blocked user on an
  unsupported build is told to update first: one of the two has to win, and the
  store link helps either way.
- **Signing out is the way out, and the screen says so.** The row is keyed on
  the address, so an anonymous session matches nothing and the app comes back —
  with every log still on the device, because none of it ever left.
- **`showDevSettingsProvider` is `!AppEnv.isProd || grants.devSettings`.** A dev
  flavour shows the group with no grant at all — that is what every build did
  before any flag existed, and a developer is usually not signed in. The
  allow-list is what adds the group to a **prod** build, which is how a
  TestFlight tester reaches the fixtures against real Firebase.
- **`_configEmailProvider` exists so the row read depends on the address, not
  on the auth stream.** `authUserProvider` emits twice on a normal launch — the
  restored session, then the same session again as data — and a provider
  watching it directly opened two Firestore listeners for one user.
- **An anonymous session never issues the row read.** It carries no address, the
  rules would deny it, and the answer is `none` either way.
- **The `app` read has no such short-circuit, and must not get one.** That is
  why `appConfigRepositoryProvider` is overridden in `pump_app.dart` for every
  widget test: without it, any tree that gates on premium opens a real Firestore
  listener.
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

Filling the collection in: `docs/rules/PENDING_SETUP.md`.
