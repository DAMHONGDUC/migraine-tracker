import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/app.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';

void main() {
  late AppDatabase db;

  Future<void> pumpApp(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const BaroEaseApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // History's StreamProvider (Drift-backed, kept alive by go_router's
  // IndexedStack) means Flutter's end-of-test "no pending timers" check can
  // trip over Drift's stream-cancellation Timer. Disposing the tree
  // ourselves, inside the test body, lets that timer fire before Flutter's
  // own invariant check runs (which happens before addTearDown callbacks).
  Future<void> finishTest(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('3 taps log an attack: intensity → location → no medication', (
    tester,
  ) async {
    await pumpApp(tester);

    // Tap 1: intensity.
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Where does it hurt?'), findsOneWidget);

    // Tap 2: head location.
    await tester.tap(find.text('Right side'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Did you take medication?'), findsOneWidget);

    // Tap 3: medication — saves immediately.
    await tester.tap(find.text('No medication'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Logged.'), findsOneWidget);

    // The attack is persisted.
    final rows = await db.select(db.attacks).get();
    expect(rows, hasLength(1));
    expect(rows.single.intensity, 7);
    expect(rows.single.location, HeadLocation.right);
    expect(rows.single.medicationName, isNull);

    await finishTest(tester);
  });

  testWidgets('logged attack appears in history', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Whole head'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('No medication'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Whole head'), findsOneWidget);
    expect(find.text('4'), findsWidgets);

    await finishTest(tester);
  });

  testWidgets('back buttons allow correcting a mis-tap', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('How intense is the pain?'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('details sheet saves symptoms, triggers and notes', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('6'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Front'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('No medication'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

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

    final row = (await db.select(db.attacks).get()).single;
    expect(row.symptoms, ['aura', 'nausea']);
    expect(row.triggers, ['stress']);
    expect(row.notes, 'bad one');

    await finishTest(tester);
  });
}
