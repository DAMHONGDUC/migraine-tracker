import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/head_diagram.dart';
import 'package:migraine_tracker/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:migraine_tracker/features/medications/domain/entities/medication.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

Attack attack({WeatherSnapshot? weather}) => Attack(
  id: 'a1',
  startedAt: DateTime.now().subtract(const Duration(hours: 2)),
  intensity: 7,
  regions: const <HeadRegion>[HeadRegion.templeR],
  medicationName: 'Sumatriptan',
  symptoms: const ['aura'],
  notes: 'bad one',
  weather: weather,
);

/// History (list mode) → tap the attack tile → detail screen.
Future<void> openDetail(WidgetTester tester) async {
  await openHistory(tester);
  await tester.tap(find.text('Right temple'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Opens one of the detail screen's edit sheets by its row label.
Future<void> openEditSheet(WidgetTester tester, String row) async {
  await tester.tap(find.text(row));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The commit button in the sheet header — a pick is only applied by this.
/// These sheets overwrite a value the attack already has, so the glyph is
/// the pencil (`SdSheetActionV2.edit`), not the tick.
Future<void> confirmSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.edit));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The X in the sheet header — leaves without applying the pick.
Future<void> closeSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close));
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
      const <HeadRegion>[HeadRegion.templeR],
    );

    await finishTest(tester);
  });

  testWidgets('the head diagram keeps its proportions on this screen', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);

    // A ListView hands children a TIGHT width, overriding HeadDiagram's
    // AspectRatio unless something loosens it — the head used to come out
    // stretched across the row. The ratio is the design box's own, 200x248.
    final Size size = tester.getSize(find.byType(HeadDiagram));
    expect(size.width / size.height, closeTo(200 / 248, 0.01));

    await finishTest(tester);
  });

  testWidgets('the medication sheet filters the tiles from its search bar', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());
    final DriftMedicationRepository medications = DriftMedicationRepository(
      app.db,
    );
    await medications.upsert(const Medication(id: 'm1', name: 'Sumatriptan'));
    await medications.upsert(const Medication(id: 'm2', name: 'Ibuprofen'));

    await openDetail(tester);
    await openEditSheet(tester, 'Medication');

    expect(find.text('Ibuprofen'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'suma');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ibuprofen'), findsNothing);
    expect(find.text('Sumatriptan'), findsWidgets);
    // The fixed first row is never filtered out.
    expect(find.text('No medication'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the head diagram follows an edit of the location', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await openEditSheet(tester, 'Location');
    await tester.tap(find.text('Crown').last);
    await tester.pump();
    await confirmSheet(tester);

    expect(
      tester.widget<HeadDiagram>(find.byType(HeadDiagram)).selected,
      // Added to what the attack already had — the tiles toggle, they do not
      // replace.
      const <HeadRegion>[HeadRegion.crown, HeadRegion.templeR],
    );

    await finishTest(tester);
  });

  testWidgets('editing the location persists and updates the screen', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await openEditSheet(tester, 'Location');
    await tester.tap(find.text('Crown').last);
    await tester.pump();
    await confirmSheet(tester);

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.regions, const <HeadRegion>[
      HeadRegion.crown,
      HeadRegion.templeR,
    ]);
    expect(find.text('Crown, Right temple'), findsOneWidget);

    await finishTest(tester);
  });

  // The point of the tick: a tap inside the sheet is a highlight, not a
  // decision, so leaving by the X must change nothing.
  testWidgets('a pick abandoned by the X changes nothing', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await openEditSheet(tester, 'Location');
    await tester.tap(find.text('Crown').last);
    await tester.pump();
    await closeSheet(tester);

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.regions, const <HeadRegion>[HeadRegion.templeR]);
    expect(find.text('Right temple'), findsOneWidget);

    await finishTest(tester);
  });

  // All three edits open a sheet now, not a dialog: the same grids the log
  // flow uses need the room, and a sheet is where this app puts a picker.
  testWidgets('each edit row opens a sheet', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);

    for (final String row in <String>['Intensity', 'Location', 'Medication']) {
      await openEditSheet(tester, row);

      expect(
        find.byType(SdSheetContentV2),
        findsOneWidget,
        reason: '$row should open a sheet',
      );
      // Every one of them offers both answers in its header. The commit is
      // the pencil, not the tick: these overwrite a value the attack has.
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      await closeSheet(tester);
    }

    await finishTest(tester);
  });

  testWidgets('the medication sheet picks "No medication"', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await openEditSheet(tester, 'Medication');
    await tester.tap(find.text('No medication').last);
    await tester.pump();
    await confirmSheet(tester);

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.medicationName, isNull);

    await finishTest(tester);
  });

  testWidgets('the intensity sheet only commits on the tick', (tester) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(attack());

    await openDetail(tester);
    await openEditSheet(tester, 'Intensity');

    // Drag the slider to the far end, then leave by the X.
    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pump();
    await closeSheet(tester);

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.intensity, 7);

    // Same drag, confirmed this time.
    await openEditSheet(tester, 'Intensity');
    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pump();
    await confirmSheet(tester);

    final rowsAfter = await app.db.select(app.db.attacks).get();
    expect(rowsAfter.single.intensity, 10);

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
