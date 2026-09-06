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

## "Delete all data" in Settings

Shipped as the free half of hard rule 8 — a row that wiped the device, the
account copy, past exports and the backend alert record, with a percentage while
it ran. Removed 2026-09-05 (owner's call). "Delete account" already performs the
same wipe as its first step, so what the row added was a second destructive
control one tap from the export row, on a screen users open to change a setting.
The cost it left behind: a signed-out user can no longer clear the backend alert
record in-app past giving up the token, which the privacy policy now answers by
email. `DataWipeService` was kept whole — account deletion and the two dev tiles
call it. **Do not restore the row without the owner asking.**

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

## An ML model behind the 7-day risk score

`PLAN.md` rules out attack prediction, and the roadmap still carries a risk
score. Both hold, because the score is deterministic weights over signals the
app already stores — pressure drop against the user's own threshold, cycle
window, sleep debt, recent frequency — and every card shows the numbers that
produced it (6.8 hPa of an 8.0 threshold → 34 of 40). A model would score the
same day 89 and be unable to say why, which is the thing a health app cannot
afford: the user must be able to disagree with it. No training data leaves the
device because there is no training. Detail in `docs/ROADMAP.md`.

## HIT-6 beside MIDAS in the doctor report

Rejected before it was built. Both measure headache disability and the pair is
what neurologists see, but HIT-6 is copyrighted by QualityMetric and shipping it
needs a paid licence, while MIDAS is free to reproduce. One score that ships is
worth more than two that block review. Revisit only if a clinic partnership pays
for the licence.

## User-defined check-in factors, the way Bearable does it

Rejected. Custom factors read as generosity and cost the analysis: the
trigger/protector map compares a factor's attack rate against its own absence,
so a factor one user invented in week three has too few days behind it to grade,
and no two users' maps mean the same thing. The check-in ships a fixed list;
adding to that list is a release decision, not a user setting.

## Menstrual cycle data in the sync payload

Kept on-device, unlike attacks and medications. The sync key is server-held
(hard rule 12), so a synced cycle row is a reproductive-health record the backend
could decrypt, and it buys the user only a second device. HealthKit already
carries the data across the user's own devices. The analyses read it locally and
sync nothing but their own conclusions.

## `if #available` in the widget bundle, a second time

The entry above says `@WidgetBundleBuilder` rejected the control flow, and that
stands for what it was about: two branches returning *different concrete types*,
because `contentMarginsDisabled()` changes the type and `some
WidgetConfiguration` admits only one. A bare `if #available(iOS 16.1, *)` around
ONE widget is a different thing — `buildLimitedAvailability`, which the builder
does implement, and Apple's own Live Activity samples are written that way. The
attack Live Activity needs it: `ActivityConfiguration` is 16.1 and the app
deploys to 15. If it does turn out not to compile, the fallback is raising the
extension's own deployment target rather than dropping the home screen widget.

## The flavour record in `shared_preferences`

The first draft of `AppFreshInstall` kept the last-launch flavour there and
cleared the whole store as its wipe. Rejected before it shipped, for two
reasons that pull the same way. Almost nothing the app writes is in prefs — the
Keychain is (`PRIVACY_AND_SECURITY.md`), so the "wipe" would have left
`onboarding_completed` and `alert_threshold: 7.0` exactly where they were. And
the one prefs key that does exist, `SdReinstallGuard.isInstalledKey`, is read by
a guard that calls *any* other key an upgrade: a `last_env` beside it would turn
the next delete-and-reinstall into an update and leave the old session signed
in — the opposite of the owner's rule that guard exists for. The record lives in
`SecureStore` instead, via `SecureFreshInstallStore`.

## Wiping the `baroease` database on a flavour change

Considered as a third wipe step, so a prod binary could not open a dev install's
seeded attacks. Left out. `AppEnv.flavor` falls back to `dev` when a build
forgets `--dart-define-from-file`, and the assert that catches that runs in
debug only — so one release built wrong would read as an environment change and
delete migraine history that has no second copy. The three steps that did ship
cost a sign-in, a cache and an onboarding run, all of which come back.
