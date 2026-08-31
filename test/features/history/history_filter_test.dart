import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:migraine_tracker/core/theme/app_icon_constant.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

Attack at(String id, DateTime local, {String? notes}) => Attack(
  id: id,
  startedAt: local.toUtc(),
  intensity: 5,
  regions: const <HeadRegion>[HeadRegion.templeL],
  notes: notes,
);

/// Opens the filter sheet from the pill.
Future<void> openFilters(WidgetTester tester) async {
  await tester.tap(find.byIcon(Symbols.filter_list_rounded));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Toggles one chip in the open sheet. It scrolls to it first: the sheet holds every axis, so most of them start below the fold.
Future<void> pickFilter(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();
}

/// Commits the draft. The confirm button is the last [SdButtonV2] in the sheet — its label counts the matches, so it cannot be found by a fixed string.
Future<void> applyFilters(WidgetTester tester) async {
  await tester.tap(find.byType(SdButtonV2).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The whole flow for one chip: open, pick, commit.
Future<void> applyFilter(WidgetTester tester, String label) async {
  await openFilters(tester);
  await pickFilter(tester, label);
  await applyFilters(tester);
}

void main() {
  testWidgets('the filter sheet narrows the list to the selected period', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    final now = DateTime.now();
    // One today, one ~10 days ago (out of "today"/"week", in "month"/"all").
    await repo.insert(at('today', DateTime(now.year, now.month, now.day, 9)));
    await repo.insert(at('old', now.subtract(const Duration(days: 10))));

    await openHistory(tester);

    // Nothing filtered → both listed, and the pill counts no axes.
    expect(find.byType(AttackTile), findsNWidgets(2));
    expect(find.text('Filters'), findsOneWidget);

    await applyFilter(tester, 'Today');
    expect(find.byType(AttackTile), findsOneWidget);
    // One axis on, which is what the pill says — the count of matches is the list itself.
    expect(find.text('Filters (1)'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a period with no attacks shows the filtered empty state', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    await repo.insert(
      at('old', DateTime.now().subtract(const Duration(days: 40))),
    );

    await openHistory(tester);
    await applyFilter(tester, 'Today');

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
    await applyFilter(tester, 'Has notes');

    expect(find.byType(AttackTile), findsOneWidget);
    expect(find.text('Filters (1)'), findsOneWidget);

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
