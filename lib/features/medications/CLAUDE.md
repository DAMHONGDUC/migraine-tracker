# Medications and reminders

- **The medications tab's app bar carries no developer tooling.** The
  `kDebugMode` "test notification" button that sat beside Search and Add is
  `_DevLocalNotificationTile` in Settings' Dev group now (owner's call): a tool
  for the person building the app has no business in the chrome of a screen
  users open, and it was one mis-tap from Add. `RemindersController.sendTest`
  still fires it; only the button moved, and `remindersTestTooltip` went with it
  out of all seven ARB files.
- **An edit-in-place field says so with a glyph, and says how it saves.** The
  medication name is read and edited in the same `SdTextFieldV2` — there is no
  reading mode and editing mode — so nothing announced that it could be changed
  at all. Its suffix carries a pencil at rest (tap to focus) that becomes a tick
  while focused (tap to save), tinted `colorScheme.secondary` like every other
  commit glyph.
  - **The tick only unfocuses.** Blur stays the single commit path, so tapping
    the tick and tapping away save through exactly the same line and there is no
    second way to write the row. Any other field that edits in place takes the
    same pair.
- **Two reminders are free across every medication — not two each.**
  `MedicationReminder.freeLimit` is that number and `canAddReminderProvider` is
  the only thing that reads it.
  - **Two and not one.** A preventive taken morning and evening, or one
    preventive plus a supplement, is the ordinary regimen, so a limit of 1
    blocks the typical user on day one, before the app has done anything for
    them, and reads as broken rather than tiered. Reminders are also what brings
    someone back daily, which is what produces the 15 attacks `minAttacks` needs
    before the correlation card is worth paying for. At 2 the wall is still hit
    by anyone on a real multi-drug regimen, in week three rather than minute one.
  - **Only the add path asks.** A free user who already holds more — from before
    the limit, or pulled down by a sync from a device that had premium — keeps
    every one of them, still firing. Taking back a reminder someone relies on to
    take their medication is a regression, not a paywall.
  - **The gate sits before the notification permission prompt**, so the OS is
    never asked on behalf of a reminder that will not be created, and the "Add
    reminder" button stays where it is with only its glyph changing to a lock —
    the label never becomes a pitch.
  - **Every record limit is named before the paywall opens**:
    `NavigationUtils.toPaywallFromLimit` shows `RecordLimitDialog`
    (`core/widgets/`) and goes on to the paywall only if the user picks Unlock.
    The reason is the button — it says "Add reminder", "Add medication", or it is
    the log button, so a purchase screen out of one reads as a bug rather than an
    offer. A surface that already announces itself as premium goes straight
    through.
  - **`docs/PREMIUM_RULES.md` is the authority** on the numbers and on every
    gate's behaviour; the limits live in `PremiumLimitConstant`, and there are
    three of them — attacks and medications as well as reminders.

## The medication-overuse warning

`MedicationOveruseBanner` counts the days this month on which any acute
medication was recorded, and says what happens past the line. It is the one
analysis in the app that exists to tell the user something they do not want
to hear.

- **It is FREE, and it is never gated.** Every other analysis is something the
  user gains by paying; this one is a harm they avoid by being told. Selling
  it would mean a paying user is warned and a free user is not.
- **It takes the top slot on the medications tab**, ahead of
  `FreeLimitProgress` — and with it the inset under the pinned filter bar,
  which only whichever sliver comes first may carry (`limitTop`/`contentTop`
  in `MedicationsScreen`). If a third sliver is ever added above these, that
  inset moves again.
- **Ten intake days a month**, where ICHD-3 8.2 puts triptans, ergots, opioids
  and combination analgesics, and where 8.2.6 puts several classes taken
  together. Simple analgesics alone are 15, but **the app does not know a
  drug's class** — there is no field for it — and the safe error is the early
  word rather than the late one.
- **It speaks at eight, not at ten.** A month is steerable at eight and spent
  at ten; a warning that arrives on the day the line is crossed is a report.
  Below eight it draws nothing at all, because a banner that appears every
  month is one nobody reads in the month it matters.
- **"Months running" appears only at three.** One heavy month is a bad month,
  and ICHD-3 asks for the pattern to hold longer than three months before it
  is medication-overuse headache at all.
- **Amber, never the error red, and never a diagnosis.** This is a course
  someone can still change; an alarm over a month they cannot undo reads as
  blame. The copy states the count and what it can lead to, then stops.

## The relief figure on the list

Each row carries its medication's relief figure (`MedicationEffectivenessLabel`
in `core/extensions/`), so the list ranks itself at a glance rather than
needing a visit to each screen in turn.

- **Under five answers it stays "helped 2 of 3 times".** A percentage off that
  few doses is 0 or 100 wearing a decimal point.
- **A medication with no answers shows nothing**, not "no outcomes yet": that
  sentence belongs on the screen that can do something about it, not on every
  row of a list.
- The engine and its rules live in `lib/features/insights/CLAUDE.md`.

## The filter strip

Three chips — date added, reminder, usage — and the two rules History's
thirteen follow, because both strips are read the same way (owner's call,
2026-08-31):

- **A chip that is narrowing the list is highlighted** (`SdFilterPillV2.active`),
  not merely labelled with its value. The label alone is a word among three
  words.
- **The strip never lifts into the app bar** — `collapsible: false`. It used to
  hand itself to the bar once scrolled; the filters now stay where they were
  put. The flag is still what the search field needs, so it is passed as a
  constant rather than removed.
- **The bar and the strip do step aside while the list scrolls**, like every
  other tab — except while searching: `pinnedChrome: _searching` holds them, or
  scrolling the results would take the field being typed in off the screen. The
  behaviour itself is `SdScrollChromeV2`, in `docs/rules/DESIGN_SYSTEM.md`.
- **`ActiveFilterSummary` (`core/widgets/`) sits above the first card**, under
  the overuse banner and the free-plan meter, saying how many axes are on and
  clearing all three in one tap (`MedicationFiltersController.reset`). Whichever
  of the three comes first still carries the strip's gap — that inset moved
  again when the summary was added (`limitTop`/`summaryTop`/`contentTop`).
