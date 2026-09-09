# Testing

What is tested, and what every change still owes.

1. `domain/correlation` — unit tests, high coverage
2. Drift migrations — a migration test per schema change
3. Pressure alert function — emulator tests: threshold edges, geohash grouping,
   dedupe window
4. Paywall entitlement gating — widget tests that free users never see premium
   data paths

## The suspension is over — the suite is green and it gates again

The redesign's churn is paid off. `flutter test` runs **1008 tests in under a
minute**, and all four priorities above are back in force, item 4 included:
`premium_gating_test.dart`, `record_limit_test.dart`, `factors_gating_test.dart`,
`risk_score_gating_test.dart` and `midas_gating_test.dart` each assert that a free
user's tree holds none of the paid vocabulary — not blurred, not offscreen, not
built and hidden.

- **The risk card is absent for a free user, not locked**, so its test asserts
  the widget renders nothing rather than asserting a pitch.
- **MIDAS has no gate of its own**: its only door is the export screen, which
  `NavigationUtils.toExport` paywalls. The test pins that, so adding a second
  door surfaces the decision instead of quietly giving it away.

**The two "known hangs" were not hangs.** They were failures. A widget test that
fails leaves work pending and is killed by the ten-minute test timeout rather
than ending at the failed expectation, so 48 failures cost 172 minutes and read
as a slow machine. Fixing the assertions took the same run to 57 seconds. **Never
diagnose a slow suite as a slow machine** — look for the first failure.

## Every screen is asked whether it fits

`test/core/screen_overflow_test.dart` pumps each surface — free and premium — and
calls `tester.takeException()`.

**A `RenderFlex` overflow is a `FlutterError` thrown during layout, not a failed
expectation.** The binding records it and the run stays green unless a test asks.
Nothing asked, and the paywall shipped 49px of striped bar across the bottom of
the screen that sells the app; it was found because an unrelated premium test
happened to pump it, not because anything was watching.

| | |
|---|---|
| Size | `pumpApp`'s own 393x852 — the design size, so an overflow is unambiguous |
| Asserts | only that the screen fits, never what it looks like |
| Why that matters | it survives a redesign that moves everything |

A new screen gets a case here in the same change that adds it.

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
