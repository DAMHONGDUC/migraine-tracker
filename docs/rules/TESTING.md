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

**Item 4 is paid for the three surfaces added after v1.0**, and those tests are
not suspended: `factors_gating_test.dart`, `risk_score_gating_test.dart` and
`midas_gating_test.dart` each assert that a free user's tree holds none of the
paid vocabulary — not blurred, not offscreen, not built and hidden.

- **The risk card is absent for a free user, not locked**, so its test asserts
  the widget renders nothing rather than asserting a pitch.
- **MIDAS has no gate of its own**: its only door is the export screen, which
  `NavigationUtils.toExport` paywalls. The test pins that, so adding a second
  door surfaces the decision instead of quietly giving it away.

**Two known hangs, both timing out at ten minutes rather than failing.** A
hanging widget test looks like a slow machine, so they are named here:

| Test | State |
|---|---|
| `health_sleep_test.dart` — two Insights-card tests | Pre-existing, confirmed by running the file at an earlier commit. Redesign churn, item of the suspension above |
| The MIDAS questionnaire screen | Cause not found; the test was dropped and what it would have asserted is covered as pure Dart in `midas_test.dart` |

## The ARB files are checked as data, not through the app

`test/core/l10n/arb_parity_test.dart` reads the seven files off disk and asserts
they carry the same keys, that the template describes every one, and that every
locale uses the same placeholders. **A key missing from one locale is a silent
fall-through to English** — no crash, no analyzer finding, nothing a normal run
notices.

It also pins the trap that cost a real bug: **`gen_l10n` orders a generated
method's positional parameters by the order the placeholders appear in the
TEMPLATE's message**, not by the order the ARB declares them. Two `int`
placeholders declared in one order and used in another compile fine and print
the wrong numbers, which is exactly what `factorsRow` did.
