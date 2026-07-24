import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('3 taps log an attack: intensity → location → no medication', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openLog(tester);

    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Where does it hurt?'), findsOneWidget);

    await tester.tap(find.text('Right side'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Did you take medication?'), findsOneWidget);

    await tester.tap(find.text('No medication').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Logged.'), findsOneWidget);

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows, hasLength(1));
    expect(rows.single.intensity, 7);
    expect(rows.single.location, HeadLocation.right);
    expect(rows.single.medicationName, isNull);

    await finishTest(tester);
  });

  testWidgets('weather snapshot is attached when the fetch succeeds', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    app.weather.snapshot = WeatherSnapshot(
      capturedAt: DateTime.utc(2026, 7, 8, 13),
      pressureHpa: 1004,
      pressureDelta24hHpa: -7.5,
    );

    await logAttack(tester);

    final snapshots = await app.db.select(app.db.weatherSnapshots).get();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.pressureDelta24hHpa, -7.5);

    await finishTest(tester);
  });

  testWidgets('offline: attack saves with no snapshot (backfilled later)', (
    tester,
  ) async {
    final app = await pumpApp(tester); // weather stub returns null

    await logAttack(tester, finish: false);

    expect(find.text('Logged.'), findsOneWidget);
    expect(await app.db.select(app.db.weatherSnapshots).get(), isEmpty);

    await finishTest(tester);
  });

  testWidgets('logged attack appears in history', (tester) async {
    await pumpApp(tester);

    await logAttack(tester, intensity: '4', location: 'Whole head');

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Whole head'), findsOneWidget);
    expect(find.text('4'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('back buttons allow correcting a mis-tap', (tester) async {
    await pumpApp(tester);
    await openLog(tester);

    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('How intense is the pain?'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('details sheet saves symptoms, triggers and notes', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    // Stay on the saved step so "Add details" is reachable.
    await logAttack(tester, intensity: '6', location: 'Front', finish: false);

    await tester.tap(find.text('Add details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.widgetWithText(TextField, 'Symptoms'),
      'aura, nausea',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Triggers'),
      'stress',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'bad one');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final row = (await app.db.select(app.db.attacks).get()).single;
    expect(row.symptoms, ['aura', 'nausea']);
    expect(row.triggers, ['stress']);
    expect(row.notes, 'bad one');

    await finishTest(tester);
  });
}
