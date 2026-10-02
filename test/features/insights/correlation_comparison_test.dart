import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/insights/domain/entities/correlation_result.dart';
import 'package:migraine_tracker/features/insights/presentation/widgets/correlation_body.dart';
import 'package:migraine_tracker/features/premium/providers.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

/// The 2026-09-30 pressure analysis: drop days against other days as two bars, labels never cut.
void main() {
  Future<void> pumpBody(WidgetTester tester, CorrelationResult result) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hasPremiumProvider.overrideWithValue(true)],
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: CorrelationBody(result: result),
              ),
            ),
          ),
        ),
      ),
    );
    // The headline percentage counts up over 700ms.
    await tester.pump(const Duration(seconds: 1));
  }

  CorrelationInsight insight({PressureBaseline? baseline}) =>
      CorrelationInsight(
        attacksAnalyzed: 12,
        requiredAttacks: 10,
        attacksDuringPressureDrop: 8,
        dropThresholdHpa: 5,
        minAttacksForShare: 5,
        baseline: baseline,
      );

  testWidgets('with a baseline, the two sides are drawn as labelled bars', (
    tester,
  ) async {
    await pumpBody(
      tester,
      insight(
        baseline: const PressureBaseline(
          dropDays: 21,
          dropDaysWithAttack: 8,
          calmDays: 64,
          calmDaysWithAttack: 8,
          minDaysPerSide: 10,
        ),
      ),
    );

    expect(find.text('Days pressure fell'), findsOneWidget);
    expect(find.text('Other days'), findsOneWidget);
    // 8/21 and 8/64, rounded.
    expect(find.text('38%'), findsOneWidget);
    expect(find.text('13%'), findsOneWidget);

    // The label is never ellipsed: it gets the card's width, not a fixed column.
    final Text label = tester.widget<Text>(find.text('Days pressure fell'));
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no baseline yet, no bars', (tester) async {
    await pumpBody(tester, insight());

    expect(find.text('Days pressure fell'), findsNothing);
    expect(find.text('Other days'), findsNothing);
  });
}
