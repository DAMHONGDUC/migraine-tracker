import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import '../../helpers/pump_app.dart';

/// Every row in the app is inset the same from both of its edges.
///
/// Material 3's own `ListTile` default is
/// `EdgeInsetsDirectional.only(start: 16, end: 24)` — asymmetric in the spec,
/// and on a card it reads plainly as a row whose two sides do not match: the
/// owner reported it on the attack detail, where the label sat 16pt from the
/// card's left edge and the chevron 24pt from its right. `AppTheme.dark` sets
/// a symmetric `listTileTheme`, and this is what stops a new screen — or a
/// Flutter upgrade moving the default again — from quietly reintroducing it.
///
/// **Symmetry is the invariant, not the number.** `EdgeInsets.zero` is
/// skipped — a handful of rows sit inside something that already pads them (a
/// sheet, a section header) and take no insets of their own — and a row that
/// picks its own tighter gutter (`HealthConnectionTile` uses 12) is its own
/// business. A row with 16 on one side and 24 on the other is never
/// deliberate, and that is all this asks.
///
/// Two surfaces, not every one: the insets come from one `listTileTheme`, so a
/// screen that draws rows at all proves the theme reached them. Settings alone
/// carries eleven.
void main() {
  /// The insets [tile] will actually be laid out with — its own, or the
  /// theme's when it has none, which is the case this test exists for.
  EdgeInsets insetsOf(WidgetTester tester, Element element) {
    final ListTile tile = element.widget as ListTile;
    final EdgeInsetsGeometry? padding =
        tile.contentPadding ?? ListTileTheme.of(element).contentPadding;

    // Null would mean neither the tile nor the theme says, which is the
    // Material default this test is about — fail loudly rather than skip.
    expect(padding, isNotNull, reason: 'no contentPadding anywhere');

    return padding!.resolve(Directionality.of(element));
  }

  Future<void> expectSymmetricRows(WidgetTester tester, String surface) async {
    final List<Element> tiles = find.byType(ListTile).evaluate().toList();
    int checked = 0;

    for (final Element element in tiles) {
      final EdgeInsets insets = insetsOf(tester, element);

      if (insets == EdgeInsets.zero) continue;
      checked++;
      expect(
        insets.left,
        insets.right,
        reason:
            '$surface: a row is inset ${insets.left} left and '
            '${insets.right} right',
      );
    }

    expect(checked, greaterThan(0), reason: '$surface: no rows to check');
  }

  testWidgets('Settings', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await expectSymmetricRows(tester, 'Settings');

    await finishTest(tester);
  });

  testWidgets('Medications, list and detail', (tester) async {
    final PumpedApp app = await pumpApp(tester);
    await DriftMedicationRepository(
      app.db,
    ).upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    await tester.pump();
    await openMedications(tester);

    await expectSymmetricRows(tester, 'medications');

    await openMedication(tester, 'Sumatriptan');

    await expectSymmetricRows(tester, 'a medication');

    await finishTest(tester);
  });
}
