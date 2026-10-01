import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/intensity_step.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/saved_step.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/pump_app.dart';

/// The 2026-09-30 log flow: the intensity grid and its legend, and the saved step reading back what it wrote.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('intensity is ten tiles in two rows of five, bands named', (
    tester,
  ) async {
    await pumpApp(tester);
    await openLog(tester);

    final Finder step = find.byType(IntensityStep);
    final List<double> rows = <double>{
      for (int value = 1; value <= 10; value++)
        tester
            .getCenter(
              find.descendant(of: step, matching: find.text('$value')),
            )
            .dy,
    }.toList();
    expect(rows, hasLength(2));
    expect(
      tester.getCenter(find.descendant(of: step, matching: find.text('5'))).dy,
      tester.getCenter(find.descendant(of: step, matching: find.text('1'))).dy,
    );

    // Colour is never the only signal: every band is named with its range.
    for (final String band in <String>[
      'Mild 1–3',
      'Moderate 4–6',
      'Severe 7–8',
      'Extreme 9–10',
    ]) {
      expect(find.text(band), findsOneWidget);
    }

    await finishTest(tester);
  });

  testWidgets('one tap on intensity still advances — the flow did not grow', (
    tester,
  ) async {
    await pumpApp(tester);
    await openLog(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(IntensityStep),
        matching: find.text('7'),
      ),
    );
    await settle(tester);

    expect(find.byType(IntensityStep), findsNothing);

    await finishTest(tester);
  });

  testWidgets('the saved step reads back what was written', (tester) async {
    await pumpApp(tester);

    await logAttack(tester, intensity: '7', finish: false);
    await settle(tester);

    final Finder saved = find.byType(SavedStep);
    expect(
      find.descendant(of: saved, matching: find.text('7 · Severe')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: saved, matching: find.text('Right temple')),
      findsOneWidget,
    );
    // Offline: no pressure row and no pattern line, never a pending one.
    expect(
      find.descendant(of: saved, matching: find.text('Pressure')),
      findsNothing,
    );
    expect(find.textContaining('pressure fell'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('a falling-pressure attack gets the pattern line', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    app.weather.snapshot = WeatherSnapshot(
      capturedAt: DateTime.now().toUtc(),
      pressureHpa: 1006.4,
      pressureDelta24hHpa: -6.8,
    );

    await logAttack(tester, finish: false);
    await settle(tester);

    expect(find.text('1006.4 hPa ↓ 6.8'), findsOneWidget);
    expect(
      find.text('Your first attack this month on a day pressure fell.'),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('a rising-pressure attack gets the reading but no line', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    app.weather.snapshot = WeatherSnapshot(
      capturedAt: DateTime.now().toUtc(),
      pressureHpa: 1015.2,
      pressureDelta24hHpa: 2.3,
    );

    await logAttack(tester, finish: false);
    await settle(tester);

    expect(find.text('1015.2 hPa ↑ 2.3'), findsOneWidget);
    expect(find.textContaining('pressure fell'), findsNothing);

    await finishTest(tester);
  });
}
