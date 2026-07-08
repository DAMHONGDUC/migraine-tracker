import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/app.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/db/database_provider.dart';
import 'package:migraine_tracker/core/l10n/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const BaroEaseApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Flutter's own end-of-test invariant check (no pending timers) runs the
  // instant a testWidgets body returns — before any addTearDown callback.
  // Disposing the widget tree here, inside the test body, lets Drift's
  // zero-duration stream-cancellation Timer (fired when a Drift-backed
  // StreamProvider is torn down) fire before that check runs.
  Future<void> finishTest(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('app boots into the log flow with bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('How intense is the pain?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No attacks logged yet.'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Language'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('theme is dark with no pure white surfaces', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byType(NavigationBar));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, isNot(Colors.white));
    expect(theme.colorScheme.surface, isNot(Colors.white));

    await finishTest(tester);
  });
}
