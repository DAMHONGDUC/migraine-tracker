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
