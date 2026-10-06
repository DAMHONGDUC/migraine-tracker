import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/features/attacks/presentation/widgets/attack_duration_sheet.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';
import 'package:system_design/index.dart';

import '../../helpers/settle_frames.dart';

/// The sheet's options are all the same kind of answer, so they are all the same kind of target.
void main() {
  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AttackDurationSheet(
                startedAt: DateTime.now().toUtc().subtract(
                  const Duration(minutes: 20),
                ),
                endedAt: null,
              ),
            ),
          ),
        ),
      ),
    );
    await settleFrames(tester);
  }

  testWidgets('"it just ended" is as tall as every other option', (
    tester,
  ) async {
    await pumpSheet(tester);

    // It sits above the grid rather than in it, so it does not get the grid's mainAxisExtent for free.
    final Size justEnded = tester.getSize(
      find.ancestor(
        of: find.text('It just ended'),
        matching: find.byType(SdPressableScaleV2),
      ),
    );
    final Size anOption = tester.getSize(
      find.ancestor(
        of: find.text('30m'),
        matching: find.byType(SdPressableScaleV2),
      ),
    );

    expect(justEnded.height, anOption.height);
  });

  testWidgets('it spans the sheet, where the grid options are half of it', (
    tester,
  ) async {
    await pumpSheet(tester);

    final double justEnded = tester
        .getSize(
          find.ancestor(
            of: find.text('It just ended'),
            matching: find.byType(SdPressableScaleV2),
          ),
        )
        .width;
    final double anOption = tester
        .getSize(
          find.ancestor(
            of: find.text('30m'),
            matching: find.byType(SdPressableScaleV2),
          ),
        )
        .width;

    expect(justEnded, greaterThan(anOption * 1.8));
  });

  /// Opens the sheet from a button, so what it pops can be read back.
  Future<List<({DateTime? endedAt})?>> openSheet(
    WidgetTester tester,
    DateTime startedAt,
  ) async {
    final List<({DateTime? endedAt})?> results = <({DateTime? endedAt})?>[];
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async => results.add(
                await AttackDurationSheet(
                  startedAt: startedAt,
                  endedAt: null,
                ).show(context),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settleFrames(tester);
    return results;
  }

  SdButtonV2 saveButton(WidgetTester tester) =>
      tester.widget<SdButtonV2>(find.widgetWithText(SdButtonV2, 'Save'));

  testWidgets('typed hours and minutes save as the end time', (tester) async {
    final DateTime startedAt = DateTime.utc(2026, 10, 1, 8);
    final List<({DateTime? endedAt})?> results = await openSheet(
      tester,
      startedAt,
    );

    // Nothing typed is nothing to save.
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), '5');
    await tester.enterText(find.byType(TextField).at(1), '40');
    await tester.pump();
    await tester.tap(find.widgetWithText(SdButtonV2, 'Save'));
    await settleFrames(tester);

    expect(results.single?.endedAt, DateTime.utc(2026, 10, 1, 13, 40));
  });

  testWidgets('minutes past 59 are refused, and so is the save', (
    tester,
  ) async {
    await openSheet(tester, DateTime.utc(2026, 10, 1, 8));

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.enterText(find.byType(TextField).at(1), '75');
    await tester.pump();

    expect(find.text('Minutes go up to 59'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
  });
}
