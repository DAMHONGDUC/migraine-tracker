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
  Future<SharedPreferences> pumpApp(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {},
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues(initialPrefs);
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
    return prefs;
  }

  Future<void> finishTest(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('switching to Vietnamese relocalizes the UI and persists', (
    tester,
  ) async {
    final prefs = await pumpApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Language'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // UI is now Vietnamese.
    expect(find.text('Cài đặt'), findsWidgets);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    // Choice is persisted for the next launch.
    expect(prefs.getString('app_locale'), 'vi');

    // The log flow is Vietnamese too.
    await tester.tap(find.text('Ghi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cơn đau dữ dội mức nào?'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a persisted Vietnamese locale is restored on launch', (
    tester,
  ) async {
    await pumpApp(tester, initialPrefs: {'app_locale': 'vi'});

    expect(find.text('Cơn đau dữ dội mức nào?'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);

    await finishTest(tester);
  });
}
