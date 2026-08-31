import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';

import '../../helpers/pump_app.dart';

Attack at(String id, DateTime local, {String? notes}) => Attack(
  id: id,
  startedAt: local.toUtc(),
  intensity: 5,
  regions: const <HeadRegion>[HeadRegion.templeL],
  notes: notes,
);

/// Opens the [axis] chip's sheet and picks [option].
///
/// A chip is labelled by its axis while it rests on "All", and the strip
/// scrolls sideways, so the chip is scrolled to first. The option is matched
/// inside the sheet's own rows — the same word can sit on a tile behind it.
Future<void> pickFilter(
  WidgetTester tester,
  String axis,
  String option,
) async {
  await tester.ensureVisible(find.text(axis));
  await tester.pump();
  await tester.tap(find.text(axis));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(
    find
        .descendant(of: find.byType(ListTile), matching: find.text(option))
        .last,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the period chip narrows the list to the selected period', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    final now = DateTime.now();
    // One today, one ~10 days ago (out of "today"/"week", in "month"/"all").
    await repo.insert(at('today', DateTime(now.year, now.month, now.day, 9)));
    await repo.insert(at('old', now.subtract(const Duration(days: 10))));

    await openHistory(tester);

    // Nothing filtered → both listed, and the chip carries its axis name.
    expect(find.byType(AttackTile), findsNWidgets(2));
    expect(find.text('Period'), findsOneWidget);

    await pickFilter(tester, 'Period', 'Today');

    expect(find.byType(AttackTile), findsOneWidget);
    // The chip carries the picked value now, not the axis name.
    expect(find.text('Today'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a filter with no matches shows the filtered empty state', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    await repo.insert(
      at('old', DateTime.now().subtract(const Duration(days: 40))),
    );

    await openHistory(tester);
    await pickFilter(tester, 'Period', 'Today');

    expect(find.text('No attacks match these filters.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('an axis other than the period narrows the list too', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    final now = DateTime.now();
    await repo.insert(
      at('noted', now.subtract(const Duration(hours: 2)), notes: 'after wine'),
    );
    await repo.insert(at('bare', now.subtract(const Duration(hours: 3))));

    await openHistory(tester);
    await pickFilter(tester, 'Notes', 'Has notes');

    expect(find.byType(AttackTile), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the app bar toggle switches between list and chart modes', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(
      app.db,
    ).insert(at('a', DateTime.now().subtract(const Duration(hours: 2))));

    await openHistory(tester);
    expect(find.byType(AttackTile), findsOneWidget); // list mode default

    await tester.tap(find.byIcon(AppIconConstant.barChart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Attacks per week'), findsOneWidget); // chart mode

    await tester.tap(find.byIcon(AppIconConstant.listView));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AttackTile), findsOneWidget);

    await finishTest(tester);
  });
}
