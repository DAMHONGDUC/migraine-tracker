import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../helpers/pump_app.dart';

Attack at(String id, DateTime local, {int intensity = 5}) => Attack(
  id: id,
  startedAt: local.toUtc(),
  intensity: intensity,
  location: HeadLocation.left,
);

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.text('History'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> switchToCalendar(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.calendar_view_month));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('calendar mode shows the calendar and hides the period filter', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(
      at('a', DateTime.now().subtract(const Duration(hours: 2))),
    );

    await openHistory(tester);
    // List mode: the filter chip is up top.
    expect(find.byIcon(Icons.filter_list), findsOneWidget);

    await switchToCalendar(tester);

    expect(find.byType(TableCalendar<Attack>), findsOneWidget);
    // Calendar navigates by month itself — no period filter.
    expect(find.byIcon(Icons.filter_list), findsNothing);

    await finishTest(tester);
  });

  testWidgets("today's attacks are listed under the calendar by default", (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final now = DateTime.now();
    await DriftAttackRepository(app.db).insert(
      at('today', DateTime(now.year, now.month, now.day, 9), intensity: 8),
    );

    await openHistory(tester);
    await switchToCalendar(tester);

    // The tile for today's attack (selection defaults to today). Scope the
    // intensity to the tile — a bare "8" would also match day 8 in the grid.
    expect(find.text('Left side'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AttackTile), matching: find.text('8')),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('a day with no attacks shows the empty message', (tester) async {
    final app = await pumpApp(tester);
    // Only an attack far in the past, so today is clear.
    await DriftAttackRepository(app.db).insert(
      at('old', DateTime.now().subtract(const Duration(days: 40))),
    );

    await openHistory(tester);
    await switchToCalendar(tester);

    expect(find.text('No attacks on this day.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('switching list → calendar → list keeps the list state', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(app.db).insert(
      at('a', DateTime.now().subtract(const Duration(hours: 2))),
    );

    await openHistory(tester);
    expect(find.text('1 attack'), findsOneWidget);

    await switchToCalendar(tester);
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1 attack'), findsOneWidget);
    expect(find.byIcon(Icons.filter_list), findsOneWidget);

    await finishTest(tester);
  });
}
