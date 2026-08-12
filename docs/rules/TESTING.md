# Testing

What is tested, what is suspended, and what is still owed.

1. `domain/correlation` — unit tests, high coverage
2. Drift migrations — test every schema change with migration tests
3. Pressure alert function — emulator tests: threshold edge cases, geohash grouping, dedupe window
4. Paywall entitlement gating — widget tests that free users never see premium data paths

### Tests are suspended for the UI redesign — owner's call, and it has an end

While the redesign described in `docs/UI_SPEC.md` is in flight, a UI change
ships without updating the widget tests it breaks, and `melos run test` is not
a gate on any of that work. The reason is the churn: a redesign moves layout,
sizes and widget identity across ~22 screens plus the design system, so most
of those tests fail on the change rather than on a bug, and fixing them screen
by screen would double the work and be redone at the next iteration anyway.

What this does NOT suspend:

- **`melos run analyze` still must pass with zero findings.** Analysis catches
  real breakage, costs seconds, and is unaffected by how a screen looks.
- **Non-UI tests stay honest.** Nothing in `domain/`, `data/`, the correlation
  engines, migrations or the Cloud Functions is covered by this — a change
  there is tested as usual.
- **The four priorities above still stand as the target.** They are deferred,
  not dropped.

**The debt is real and must be paid before release**: the paywall gating tests
(item 4) are the ones that matter most, because they are what proves a free
user's tree holds no premium data. Do not let this section quietly become
permanent — when the redesign settles, restore the suite and delete this
subsection in the same change.
