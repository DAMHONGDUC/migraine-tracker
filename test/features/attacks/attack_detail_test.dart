import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/widgets/app_sheet_content.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_diagram.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/pump_app.dart';

Attack attack({WeatherSnapshot? weather}) => Attack(
  id: 'a1',
  startedAt: DateTime.now().subtract(const Duration(hours: 2)),
  intensity: 7,
  location: HeadLocation.right,
  medicationName: 'Sumatriptan',
  symptoms: const ['aura'],
  notes: 'bad one',
  weather: weather,
);

/// History (list mode) → tap the attack tile → detail screen.
Future<void> openDetail(WidgetTester tester) async {
  await openHistory(tester);
  await tester.tap(find.text('Right side'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('tapping an attack opens its detail with weather and details', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(
      attack(
        weather: WeatherSnapshot(
          capturedAt: DateTime.now().toUtc(),
          pressureHpa: 1004.2,
          pressureDelta24hHpa: -7.5,
          humidityPercent: 71,
          temperatureCelsius: 19.3,
        ),
      ),
    );

    await openDetail(tester);

    expect(find.text('Attack details'), findsOneWidget);
    expect(find.text('Sumatriptan'), findsOneWidget);
    expect(find.text('1004.2 hPa'), findsOneWidget);
    expect(find.text('-7.5 hPa'), findsOneWidget); // the drop
    expect(find.text('71%'), findsOneWidget);

    // The details section sits below the fold — scroll like a user would.
    await tester.dragUntilVisible(
      find.text('bad one'),
      find.byType(ListView).last,
      const Offset(0, -120),
    );
    await tester.pump();
    expect(find.text('aura'), findsOneWidget);
    expect(find.text('bad one'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('an offline attack shows the no-weather state', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);

    expect(find.text('No weather data attached yet.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the head diagram shows the logged location', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);

    expect(
      tester.widget<HeadDiagram>(find.byType(HeadDiagram)).selected,
      HeadLocation.right,
    );

    await finishTest(tester);
  });

  testWidgets('the head diagram follows an edit of the location', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await tester.tap(find.text('Location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Whole head').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.widget<HeadDiagram>(find.byType(HeadDiagram)).selected,
      HeadLocation.whole,
    );

    await finishTest(tester);
  });

  testWidgets('editing the location persists and updates the screen', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    // Tap the Location row's value.
    await tester.tap(find.text('Location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Whole head').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.location, HeadLocation.whole);
    expect(find.text('Whole head'), findsOneWidget);

    await finishTest(tester);
  });

  // All three edits open a sheet now, not a dialog: the same grids the log
  // flow uses need the room, and a sheet is where this app puts a picker.
  testWidgets('each edit row opens a sheet', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);

    for (final String row in <String>['Intensity', 'Location', 'Medication']) {
      await tester.tap(find.text(row));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(AppSheetContent),
        findsOneWidget,
        reason: '$row should open a sheet',
      );

      // Dismiss by popping the sheet route, the way the barrier would.
      Navigator.of(tester.element(find.byType(AppSheetContent))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await finishTest(tester);
  });

  testWidgets('the medication sheet picks "No medication"', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await tester.tap(find.text('Medication'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('No medication').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.medicationName, isNull);

    await finishTest(tester);
  });

  testWidgets('the intensity sheet only commits on Save', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await tester.tap(find.text('Intensity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Drag the slider to the far end, then leave without saving.
    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pump();
    Navigator.of(tester.element(find.byType(AppSheetContent))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.intensity, 7);

    await finishTest(tester);
  });

  testWidgets('deleting from the detail screen removes it and pops back', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Delete this attack?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(await app.db.select(app.db.attacks).get(), isEmpty);
    // Back on History, which is empty again.
    expect(find.text('No attacks logged yet.'), findsOneWidget);

    await finishTest(tester);
  });
}
