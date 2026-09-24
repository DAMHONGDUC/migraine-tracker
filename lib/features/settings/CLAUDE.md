# Settings

- **The account row says whether there is an account, without being opened**
  (owner's call). Two `SdTagV2`s of the same shape — "Signed in" in the accent,
  "Not signed in" in the muted grey the alerts row wears when it is off — so
  colour is what tells them apart at a glance. It read "Sign in" or "Account" and
  nothing else before, so the one state a user opens Settings to check was two
  taps away, and "Account" on an anonymous session looked like an account.
  - **The state, never the address** (owner's call, reversing a version that
    printed the email). Settings is read in public; an address on a row anyone
    glancing over can see is a cost the answer does not need. The account screen
    behind it is where the address belongs.
- **The subscription row is the same pair**: `PremiumBadge` when it is on — the
  actual widget, so the row and every other premium marker in the app cannot
  come out different — and a muted "Free" tag when it is not. One word each;
  "Premium is active" was a sentence where the row only had to name a state.
  Those longer lines still stand where there is room for them, on the account and
  subscription screens.

## The export preview

**The PDF preview's surround is the app's own background, not the package's.**
`PdfPreview` defaults to a light grey gradient — a bright panel filling the
screen of an app whose users are photophobic — so `scrollViewDecoration` is set
and `pdfPreviewPageDecoration` replaces its hard offset black shadow with the
calm one everything else on a dark surface wears.

- **The page itself stays white.** It is paper: a doctor report tinted to match
  the app would print wrong and read as a rendering fault.
- **Both previews name the file** (`_FileName`), because the app bar says only
  what kind of screen this is. It carries no gutter of its own — the text
  preview sits inside an already-padded list.
- **`onError` draws the same missing-file state as the outer branch.** The
  package's own is red English on grey.

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

## Export, and the wipe that is gone

**The export screen is premium in full, and the gate is on the door rather than
inside it.** JSON, CSV and the PDF report all sit behind it (owner's call,
2026-08-19 — `docs/PREMIUM_RULES.md` carries the reasoning and the one cost it
buys). Both entrances — the Settings row and the dashboard's explore card — wear
a `PremiumBadge` and go through `NavigationUtils.toExport`, so `ExportKindSheet`
has no per-row gate any more.

**The "Delete all data" row next to it is removed** (owner's call, 2026-09-05),
along with its dialog, its progress indicator and the `AppFeature.wipe` row in
`AppFeatureList`. "Delete account" is the only teardown the app offers *users*
now; `DataWipeService` is still what performs it. Detail and what the removal
costs a signed-out user: hard rule 8 in `docs/rules/PRIVACY_AND_SECURITY.md`.
The row came back in the Dev group and nowhere else (below) — the removal was
about what a user is offered, not about the wipe existing.

**`SettingsController` is a plain `Provider`, not a `Notifier`** — the wipe
progress was the only state it ever held. It keeps the three dev actions, and
every dev tile carries its own `_running` flag.

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
- **The "Apple Health" group is gone from Settings** (owner's call): the two
  switches moved onto the Insights tabs they fill, where the user is already
  looking at the empty chart. Settings keeps the rows that lead there.
  **Submission 1.0(11) was rejected under App Store 2.5.1 for not identifying
  HealthKit in the UI**, and that group was the answer — so what carries the
  identification now is the switch's own title ("Apple Health sleep", "Apple
  Health steps") and the caption under it, on a tab in the main nav and behind no
  gate. Do not rename those switches to "Sleep" and "Steps": that is the exact
  wording the rejection was about. Detail: `lib/features/insights/CLAUDE.md`.
  The removed group was absent off iOS
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

## The sync card

**Signed in, a sync card sits at the very top — above the Dev group** (owner's
rule, 2026-09-24). It shows a running sync's progress, how many changes are not
saved to the account yet, or that everything is. Sign-out refuses while
anything is owed, so this is where a user sees that coming. Detail and states:
`lib/features/sync/CLAUDE.md`, "Where sync is visible".

- **While syncing it shows a percentage beside the title** (owner's rule), with
  the record count under it and the bar below.
- **The Dev group carries "Sync everything now"** (`_DevSyncTile`, signed in
  only) so the card can be watched on demand; see the sync doc for what it does.

## The Dev group

**It is FIRST among the groups, above General** (owner's rule; only the sync
card sits above it): it is the group a
developer opens Settings for, and below every real section it meant scrolling
past the whole app to reach the tools that build the state being tested.

- **`showDevSettingsProvider` decides, not the flavour alone.** It is
  `!AppEnv.isProd || grants.devSettings`: a dev flavour shows the group with no
  grant at all — exactly what the screen did before any of this existed — and a
  address on `dev_mode_emails` in `app_config/current` is how a TestFlight tester reaches the
  fixtures against real Firebase, which a dev flavour cannot give them. It was
  the `SHOW_DEV_SETTINGS` build flag, and moved to Firestore so that granting a
  tester the group no longer needs a new binary
  (`lib/features/app_config/CLAUDE.md`).
  - **Two rows stay on `!AppEnv.isProd` regardless**: `_DevPremiumTile` and
    `_DevLocationTile`. `hasPremiumProvider` ignores `DevPremiumOverride` in
    prod and `DevLocationController` returns `off` there, so under the flag they
    would be controls that visibly do nothing — worse than absent.
- **`first: true` follows whichever heading is actually first**: Dev takes it
  whenever it is shown, General is `first: !showDev`. The flag is
  the screen's own top gap, so two headings claiming it would double the gap and
  neither claiming it would lose it.
- **`_DevDeleteDataTile` and `_DevResetTile` are two teardowns, not one**, and
  sit in that order — the gentler first. `deleteAllData` empties the device and
  the account's synced copy and leaves the user on Settings, so every screen can
  be looked at in its empty state without a reinstall; `resetToOnboarding` is
  that plus the onboarding flags, and navigates. Before the pair existed, seeing
  an empty state meant a reset and then walking back through onboarding, which
  is why the wipe alone earns its own row.
  - **The delete row does not navigate, and must not start.** The screen it was
    tapped from is the point: a redirect would put the developer somewhere they
    then have to come back from. It is `_DevResetTile` that has to `goNamed`,
    because the router only redirects to onboarding on a route change.
  - **`settings_gdpr_test.dart` asserts the row sits above the General
    heading**, not that it is absent. Tests run the dev flavour, so the group is
    always on screen there; a bare `findsNothing` would fail the moment the row
    came back, and a bare `findsOneWidget` would pass if it were moved into "Your
    data". Position is what says "developer-only" in a test that cannot turn the
    group off.
- **`_DevLocalNotificationTile` is the local half of the delivery path and needs
  no account.** It sits beside `_DevPushTile` but outside that pair's
  `isSignedInProvider` gate — a local notification is scheduled by the OS on the
  device, which is the distinction the two rows exist to draw: when a reminder
  never arrives, one says the fault is on the device and the other says it is in
  the backend. It came from the medications tab's app bar, where a `kDebugMode`
  button sat in the chrome of a screen users see.
