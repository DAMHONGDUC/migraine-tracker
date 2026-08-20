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
