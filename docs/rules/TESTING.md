# Testing

What is tested, what is suspended, and what is still owed.

1. `domain/correlation` — unit tests, high coverage
2. Drift migrations — a migration test per schema change
3. Pressure alert function — emulator tests: threshold edges, geohash grouping,
   dedupe window
4. Paywall entitlement gating — widget tests that free users never see premium
   data paths

## Tests are suspended for the UI redesign — owner's call, and it has an end

While the redesign in `docs/archive/UI_SPEC.md` is in flight, a UI change ships
without updating the widget tests it breaks, and `sh packages/system_design/tool/test.sh` gates none of
that work. The reason is churn: the redesign moves layout, sizes and widget
identity across ~22 screens plus the design system, so most of those tests fail
on the change rather than on a bug, and fixing them screen by screen would be
redone at the next iteration.

What this does **not** suspend:

- **`sh packages/system_design/tool/analyze.sh` still passes with zero findings.** It catches real
  breakage, costs seconds, and does not care how a screen looks.
- **Non-UI tests stay honest.** `domain/`, `data/`, the correlation engines,
  migrations and the Cloud Functions are unaffected.
- **The four priorities above still stand.** Deferred, not dropped.

**The debt must be paid before release**, item 4 most of all — it is what proves
a free user's tree holds no premium data. When the redesign settles, restore the
suite and delete this section in the same change.
