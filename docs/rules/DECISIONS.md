# Decisions — things tried and reverted

Kept out of the always-loaded path because none of it is actionable on its
own. Read it before changing a rule that looks arbitrary: each entry is
something that WAS done the other way and cost something.

The rule itself lives where the routing table in `CLAUDE.md` says. This file
only says why it is what it is.

## The whole app on CocoaPods

Tried, to escape the `exact:` pin conflicts in the Firebase plugin family.
Reverted for two reasons: a cold build went from ~80s to ~390s, and — the
decisive one — Firebase is dropping CocoaPods (no new versions after October
2026, registry read-only from December 2026). Staying would have frozen the
Firebase SDK with no security fixes, which is not a place a health app can
sit. Full detail in `docs/rules/TECH_STACK.md`.

## The premium boundary, which has moved three times

1. Forecast premium.
2. Reversed to free — "seeing the pressure you live in is the app's own
   promise".
3. Premium again, once `WeatherCard` carried the free weather.

The promise is now kept by the weather card; the pressure chart is the paid
reading. **Do not flip it a fourth time without the owner saying so.**
`docs/PREMIUM_RULES.md` is the authority on where it currently stands.

## Alert controls shown inert to free users

Built that way first, on the theory that a locked control still says what it
would do. It does not: a switch that will not switch and a threshold row that
will not open read as a broken screen rather than as an offer. A free user now
sees neither control.

## Blurred sample analyses on the activity and sleep cards

`PremiumChartLock` over a fabricated sample was used on both. Removed by the
owner: it cost a full second analysis render to show something deliberately
unreadable, and the badge on the heading already said what the section was.
One line and an Unlock button replaced it. History's chart deck still uses the
blur.

## An `AppLogger.guard(action)` combinator

Rejected. A closure-taking wrapper hides the flow; every `catch` is written
inline instead, even though it is more verbose.

## The home screen widget switch defaulting off

Tried and reversed. There is no API for placing a widget on a home screen, so
adding it is the user's own explicit act and that act *is* the opt-in.
Defaulting the feed off meant a widget the user had just added showing dashes.

## Two widgets behind `if #available` for iOS 17 content margins

Does not compile: `contentMarginsDisabled()` returns a different concrete type,
`some WidgetConfiguration` admits only one, and `@WidgetBundleBuilder` rejects
the control flow. Do not re-propose it. Detail in
`lib/features/home_widget/CLAUDE.md`.

## `assert(AppEnv.hasFirebaseConfig)` as the TestFlight crash

Suspected and closed. Dart strips `assert()` from release builds, so it cannot
fire there. The crash was RevenueCat answering a `test_...` key with a native
`fatalError`, which no Dart `catch` can survive. Detail in
`docs/rules/PENDING_SETUP.md`.

## The bare `GridView(children: [...])` constructor in the exertion picker

Hung `log_flow_test.dart` on a test it did not touch, rather than failing it.
The same delegate through `GridView.builder` runs clean. The cause was never
found — treat the bare constructor as the thing to avoid here.

## A 12h sync throttle for the notification list

Owner: skip it for now. It conflicted with pushing a freshly logged attack,
which exists so an attack is not lost with the phone.
