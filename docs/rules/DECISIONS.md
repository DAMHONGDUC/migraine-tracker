# Decisions — things tried and reverted

Kept out of the always-loaded path because none of it is actionable on its own.
Read it before changing a rule that looks arbitrary: every entry WAS done the
other way and cost something. The rule itself lives where `CLAUDE.md`'s routing
table says; this file only says why it is what it is.

## The whole app on CocoaPods

Tried, to escape the `exact:` pin conflicts in the Firebase plugin family.
Reverted: a cold build went from ~80s to ~390s, and Firebase is dropping
CocoaPods (no new versions after October 2026), which would have frozen the SDK
with no security fixes. Detail in `TECH_STACK.md`.

## The premium boundary, which has moved three times

Forecast premium → free ("seeing the pressure you live in is the app's own
promise") → premium again, once `WeatherCard` carried the free weather. The
promise is now kept by the weather card; the pressure chart is the paid reading.
**Do not flip it a fourth time without the owner saying so.**
`docs/PREMIUM_RULES.md` is the authority.

## A lifetime purchase alongside the two subscriptions

`PLAN.md` §3 sold a $44.99 non-consumable, on the reasoning that chronic-illness
communities prefer one-time purchases. Dropped 2026-08-29 (owner's call): the
app's own cost recurs forever — a WeatherKit call per alert, the pressure cron,
Firestore — so the heaviest users, the ones the lifetime tier attracts, are the
ones it earns least from, and a non-consumable can never be re-priced. The row
is gone from `PremiumPeriod` and `_periodOf` skips `PackageType.lifetime`, so an
offering still carrying the product renders two plans rather than three. Anyone
who bought one keeps the entitlement: nothing reads the period to decide access.

## Premium gated on an account as well as an entitlement

`hasPremiumProvider` required a signed-in user, and the paywall showed a "Sign
in to continue" CTA with the prices hidden behind it — the reasoning being that
a subscription needs something that survives a reinstall. App Store review
rejected it under 5.1.1(v) (submission 1.0(20)): the content is not
account-based, so registration cannot be required to buy it. A reinstall is what
Restore is for. `docs/PREMIUM_RULES.md` is the rule.

## A "Not now" beside the location explainer

Onboarding's location page offered "Enable location" and "Not now", so a user
could walk past the OS prompt entirely and the weather card had to ask again
later. App Store review rejected both halves under 5.1.1(iv) (submission
1.0(20)): the button may not be worded as the grant, and the explainer may not
offer a way to skip the prompt. One "Continue" now, and iOS's dialog always
follows. `docs/rules/PRIVACY_AND_SECURITY.md` §2 is the rule.

## Alert controls shown inert to free users

Built that way on the theory that a locked control still says what it would do.
It does not: a switch that will not switch reads as a broken screen, not an
offer. A free user now sees neither control.

## Blurred sample analyses on the activity and sleep cards

`PremiumChartLock` over a fabricated sample, on both. Removed by the owner: it
cost a second analysis render to show something deliberately unreadable, and the
badge on the heading already said what the section was. One line and an Unlock
button replaced it. History's chart deck still uses the blur.

## An `AppLogger.guard(action)` combinator

Rejected — a closure-taking wrapper hides the flow. Every `catch` is written
inline instead, verbosity included.

## The home screen widget switch defaulting off

Reversed. There is no API for placing a widget on a home screen, so adding it is
the user's explicit act and that act *is* the opt-in. Defaulting the feed off
meant a widget the user had just added showing dashes.

## Two widgets behind `if #available` for iOS 17 content margins

Does not compile: `contentMarginsDisabled()` returns a different concrete type,
`some WidgetConfiguration` admits only one, and `@WidgetBundleBuilder` rejects
the control flow. Do not re-propose. Detail in
`lib/features/home_widget/CLAUDE.md`.

## `assert(AppEnv.hasFirebaseConfig)` as the TestFlight crash

Suspected and closed — Dart strips `assert()` from release builds. The crash was
RevenueCat answering a `test_...` key with a native `fatalError`, which no Dart
`catch` can survive. Detail in `PENDING_SETUP.md`.

## The bare `GridView(children: [...])` constructor in the exertion picker

Hung `log_flow_test.dart` on a test it did not touch, rather than failing it. The
same delegate through `GridView.builder` runs clean. The cause was never found —
avoid the bare constructor here.

## A 12h sync throttle for the notification list

Owner: skip it for now. It conflicted with pushing a freshly logged attack,
which exists so an attack is not lost with the phone.
