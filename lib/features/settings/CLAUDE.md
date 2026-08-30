# Settings

## The feature list

**One widget, `AppFeatureList` (`core/widgets/`), strings `appFeature*`.** Two
surfaces show it — the onboarding sheet and the About screen — so it moved out
of `onboarding/` and the ARB keys lost their `onboarding` prefix. Adding a
feature is one `AppFeature` entry plus its two keys in every locale; a second
hand-built list of the same rows is how one ends up a release behind.

**The three capped features state their limit in their own row** — log,
medications, reminders — as a `{count}` placeholder filled from
`PremiumLimitConstant`, never a number typed into the ARB. The About screen is
where a user goes to find out what the free plan holds, and it said nothing
about the limits at all. The onboarding sheet's `appFeaturesBody` summary still
names all three, which is fine now that both read the same constants.

## Export and the wipe

**The export screen is premium in full, and the gate is on the door rather than
inside it.** JSON, CSV and the PDF report all sit behind it (owner's call,
2026-08-19 — `docs/PREMIUM_RULES.md` carries the reasoning and the one cost it
buys). Both entrances — the Settings row and the dashboard's explore card — wear
a `PremiumBadge` and go through `NavigationUtils.toExport`, so `ExportKindSheet`
has no per-row gate any more.

**The wipe next to it stays free** and must: hard rule 8 makes deleting your own
records a promise, and a paywall in front of it would be the one gate the app
cannot defend.

- **A test that opens the export screen must `pumpApp(premium: true)`** —
  `openExportScreen` taps a row that answers a free user with the paywall, and
  every assertion after it would be made against the wrong screen.
- **The doctor report falls back to English in Japanese and Chinese.** The PDF
  embeds `assets/fonts/noto_sans/`, which is Latin-only, so a CJK locale would
  print blank boxes for every glyph — including the head-location labels and the
  disclaimer, which come from ordinary UI keys, so translating the `report*` keys
  alone would not have saved it. `DoctorReportStringsL10n.doctorReportStrings`
  swaps in `AppLocalizationsEn()` for `ExportConstant.reportFontlessLocales`, so
  the fallback is one place. The alternative is bundling a CJK face for ~16 MB;
  revisit if those markets grow.

## The five groups

General, Monitoring, Apple Health, Your data, About — plus Dev off prod.

**"Monitoring" is pressure, activity, sleep and the home screen widget**, each
opening a surface with its own switches. They had been in General between the
sign-in row and the language picker, which made that group a list of unrelated
things. Pressure leads it because it is the app's own subject; the widget is
last, because it is where the others get shown rather than another thing being
watched.

- **That group was called "Tracking" and must not go back to it.** Owner's call,
  after submission 1.0(11) came back under 5.1.2(i) over privacy labels claiming
  tracking the app does not do. On the App Store the word means following a user
  across other companies' apps for advertising — the opposite of a barometer and
  this device's own health data watched on the user's behalf. Same meaning
  without a reviewer having to pick which sense was intended. The ARB key, the
  section widget and its part file carry the new name too: a key named for a word
  the UI no longer says sends the next editor to the wrong place. Chinese kept
  监测 — that already meant monitoring, never the advertising sense (跟踪).
- **"Apple Health" exists to be found, and it is iOS-only.** `_HealthSection`
  holds the sleep and step connect switches — the same `HealthConnectionTile` and
  the same provider `/sleep` and `/activity` use, so the surfaces cannot disagree
  about what is connected — plus one caption saying what is read and that it never
  leaves the device. The switches stay on the detail screens too; that is where a
  user changes their mind. It is a top-level group rather than two rows under
  Monitoring because **submission 1.0(11) was rejected under App Store 2.5.1 for
  not identifying HealthKit in the UI**: the only entrances were rows named
  "Sleep" and "Activity", neither saying "Apple Health", and the sleep one was
  premium-gated on top. The whole group is absent off iOS
  (`healthAvailableProvider`) — heading included, since a heading over nothing
  reads as a screen that failed to load.

## No countdown

**There is no premium promo banner on Settings, and no countdown anywhere**
(owner's call). `PremiumCountdownBanner` and the `HighlightedTimeText` only it
used are deleted, along with `dashboardSaleTitle` and `dashboardSaleEndsIn`: on
Settings it was a countdown on an evergreen "today only" deal, at the top of a
screen the user opened to change something. **The dashboard has a promo again** —
`PremiumBanner`, one line, no timer, no second button (see
`lib/features/dashboard/CLAUDE.md`); what this rule forbids is the *countdown*,
not the offer. Premium is also sold by the Settings row, every `PremiumGate`,
`RecordLimitDialog` and the locked cards.

## The Dev group

**It is FIRST on the screen, above General** (owner's rule): it is the group a
developer opens Settings for, and below every real section it meant scrolling
past the whole app to reach the tools that build the state being tested.

- **`showDevSettingsProvider` decides, not the flavour alone.** It is
  `!AppEnv.isProd || grants.devSettings`: a dev flavour shows the group with no
  grant at all — exactly what the screen did before any of this existed — and a
  `dev_settings: true` row in `app_access` is how a TestFlight tester reaches the
  fixtures against real Firebase, which a dev flavour cannot give them. It was
  the `SHOW_DEV_SETTINGS` build flag, and moved to Firestore so that granting a
  tester the group no longer needs a new binary
  (`lib/features/access/CLAUDE.md`).
  - **Two rows stay on `!AppEnv.isProd` regardless**: `_DevPremiumTile` and
    `_DevLocationTile`. `hasPremiumProvider` ignores `DevPremiumOverride` in
    prod and `DevLocationController` returns `off` there, so under the flag they
    would be controls that visibly do nothing — worse than absent.
- **`first: true` follows whichever heading is actually first**: Dev takes it
  whenever it is shown, General is `first: !showDev`. The flag is
  the screen's own top gap, so two headings claiming it would double the gap and
  neither claiming it would lose it.
- **`_DevLocalNotificationTile` is the local half of the delivery path and needs
  no account.** It sits beside `_DevPushTile` but outside that pair's
  `isSignedInProvider` gate — a local notification is scheduled by the OS on the
  device, which is the distinction the two rows exist to draw: when a reminder
  never arrives, one says the fault is on the device and the other says it is in
  the backend. It came from the medications tab's app bar, where a `kDebugMode`
  button sat in the chrome of a screen users see.
