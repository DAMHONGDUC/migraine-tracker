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
- **Medications and reminders are unlimited** (owner's rule, 2026-10-10;
  `docs/PREMIUM_RULES.md`). The add buttons go straight to the name dialog and
  the permission prompt; there is no limit dialog and no meter.

## The medication-overuse warning

`MedicationOveruseBanner` counts the days this month on which any acute
medication was recorded, and says what happens past the line. It is the one
analysis in the app that exists to tell the user something they do not want
to hear.

- **It is FREE, and it is never gated.** Every other analysis is something the
  user gains by paying; this one is a harm they avoid by being told. Selling
  it would mean a paying user is warned and a free user is not.
- **It takes the top slot on the medications tab**, and with it the inset
  under the pinned filter bar, which only whichever sliver comes first may
  carry (`summaryTop`/`contentTop` in `MedicationsScreen`). If a third sliver is ever added above these, that
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

The all-filters pill, then three chips — date added, reminder, usage — and the two rules History's
thirteen follow, because both strips are read the same way (owner's call,
2026-08-31):

- **The all-filters pill leads the strip**, opening the three axes in one
  `AllFiltersSheet` — the same pill and sheet History uses (owner's call,
  2026-10-05). The chips stay; Apply commits through
  `MedicationFiltersController.apply`.
- **A chip that is narrowing the list is highlighted** (`SdFilterPillV2.active`),
  not merely labelled with its value. The label alone is a word among three
  words.
- **The strip never lifts into the app bar** — `collapsible: false`. It used to
  hand itself to the bar once scrolled; the filters now stay where they were
  put. The flag is still what the search field needs, so it is passed as a
  constant rather than removed.
- **`ActiveFilterSummary` (`core/widgets/`) sits above the first card**, under
  the overuse banner and the free-plan meter, saying how many axes are on and
  clearing all three in one tap (`MedicationFiltersController.reset`). Whichever
  of the three comes first still carries the strip's gap — that inset moved
  again when the summary was added (`limitTop`/`summaryTop`/`contentTop`).
