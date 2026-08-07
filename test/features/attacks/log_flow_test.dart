import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/exertion_level_picker.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('3 taps then the exertion default log an attack', (tester) async {
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
    expect(find.text('Were you exerting yourself?'), findsOneWidget);

    // Nothing touched: the step arrives on "None", so Next is already armed
    // and this step can never stand between the user and a saved attack.
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Logged.'), findsOneWidget);

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows, hasLength(1));
    expect(rows.single.intensity, 7);
    expect(rows.single.location, HeadLocation.right);
    expect(rows.single.medicationName, isNull);
    expect(rows.single.exertionLevel, ExertionLevel.none);

    await finishTest(tester);
  });

  testWidgets('picking an exertion level stores it on the attack', (
    tester,
  ) async {
    final app = await pumpApp(tester);

    await logAttack(tester, exertion: 'Severe');

    final rows = await app.db.select(app.db.attacks).get();
    expect(rows.single.exertionLevel, ExertionLevel.severe);

    await finishTest(tester);
  });

  testWidgets('the exertion options sit two to a row, each half the width', (
    tester,
  ) async {
    await pumpApp(tester);

    // Walk to the exertion step without leaving it (logAttack taps past it).
    await openLog(tester);
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Right side'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('No medication').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Were you exerting yourself?'), findsOneWidget);

    final Finder tiles = find.descendant(
      of: find.byType(ExertionLevelPicker),
      matching: find.byType(SdPressableScaleV2),
    );
    expect(tiles, findsNWidgets(ExertionLevel.values.length));

    final List<Rect> rects = <Rect>[
      for (int i = 0; i < ExertionLevel.values.length; i++)
        tester.getRect(tiles.at(i)),
    ];

    // Two to a row: 0|1 share a top edge, 2|3 share a lower one.
    expect(rects[0].top, rects[1].top);
    expect(rects[2].top, rects[3].top);
    expect(rects[2].top, greaterThan(rects[0].top));

    // Half the width each: the four tiles are one width, the two columns
    // line up across both rows, and the pair spans the step edge to edge.
    final double width = rects.first.width;
    for (final Rect rect in rects) {
      expect(rect.width, moreOrLessEquals(width, epsilon: 0.01));
    }
    expect(rects[0].left, rects[2].left);
    expect(rects[1].left, rects[3].left);
    expect(
      rects[1].right - rects[0].left,
      moreOrLessEquals(
        tester.view.physicalSize.width / tester.view.devicePixelRatio -
            SdContentPaddingV2.horizontal * 2,
        epsilon: 1,
      ),
    );

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
    await tester.tap(find.byType(SdAppBarButtonV2));
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

    await tester.enterText(findLabelledField('Symptoms'), 'aura, nausea');
    await tester.enterText(findLabelledField('Triggers'), 'stress');
    await tester.enterText(findLabelledField('Notes'), 'bad one');
    // The details sheet commits from its header — a pencil, since it
    // overwrites details the attack may already carry.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final row = (await app.db.select(app.db.attacks).get()).single;
    expect(row.symptoms, ['aura', 'nausea']);
    expect(row.triggers, ['stress']);
    expect(row.notes, 'bad one');

    await finishTest(tester);
  });
}
