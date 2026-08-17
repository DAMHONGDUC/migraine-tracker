# Review prompt

`PLAN.md` §7: the store review prompt arrives "after a value moment — first
PDF export or first correct pressure alert". This feature is that sentence and
nothing more.

- **Two moments, and both are results the user would name.** `ReviewMoment`
  has exactly two values: a doctor report reaching the share sheet, and an
  attack logged inside `ReviewPromptConstant.alertHitWindow` after a pressure
  alert — the alert the subscription is *for* turning out to be right. A third
  entry point means arguing it is a result, not just a screen the user reached.
  - **An attack alone is not a moment.** Logging one is the app working, not
    the app being right, and someone mid-migraine is the last person to ask
    for a rating. The alert has to have come first: `ReviewPromptPolicy`
    refuses an attack that predates the alert however close it is.
- **Never wire `requestReview` to a button.** Apple's guidelines forbid a
  control that calls it — the dialog has to arrive unprompted. `openStoreListing`
  is the API for a "Rate this app" row, and nothing here has one yet.
- **The caps are ours, not just the OS's.** iOS drops everything past three
  prompts per 365 days and tells nobody, so `ReviewPromptConstant` holds the
  same cap plus a 120-day floor between asks. Asking past the cap is not an
  error — it is a moment spent on a dialog that never appeared, and the next
  real one is wasted too.
- **Only a real ask is recorded.** `ReviewPrompter.request` answers false when
  the platform has no review flow (every simulator, a sideloaded build).
  Recording that would spend one of three on nothing and silence the next
  moment for four months. What is stored is what we *asked for* — nobody ever
  tells us whether the dialog drew, let alone whether anyone rated anything.
- **Every entry point is best-effort and is called unawaited.** A review
  prompt is the least important thing on the screen it interrupts, so
  `ReviewPromptController` logs its failures and rethrows none of them, the
  same shape as the weather backfill (hard rule 4). Both call sites —
  `ExportController.share` and `LogController._save` — wrap it in `unawaited`.
- **No ARB strings.** The OS owns the dialog, its text and its locale. There is
  nothing here for `app_en.arb` to hold, which is why this feature has no
  `presentation/screens/`.
- **`pumpApp` overrides `reviewPrompterProvider`** with
  `RecordingReviewPrompter` (`test/helpers/review_fakes.dart`). Every saved
  attack reaches this controller, and the real prompter is a platform channel
  no widget test has.
- The state lives in `shared_preferences`, not the database, and **never
  syncs**: the cap it feeds is one device's OS quota, so a second phone gets
  its own three.
