import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_colors.dart';
import 'package:migraine_tracker/features/settings/presentation/widgets/date_range_calendar.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

import '../../helpers/settle_frames.dart';

void main() {
  /// Pumps the calendar alone, pinned to the 393×852 design size that screenutil's `.r`/`.sp` assume (see `pumpApp`'s note).
  Future<void> pumpCalendar(
    WidgetTester tester, {
    DateTime? from,
    DateTime? to,
    DateTime? firstDate,
    ValueChanged<DateTime>? onDateSelected,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DateRangeCalendar(
              from: from,
              to: to,
              firstDate: firstDate ?? DateTime(2025),
              lastDate: DateTime(2026, 3, 31),
              initialMonth: DateTime(2026, 3),
              onDateSelected: onDateSelected ?? (DateTime _) {},
            ),
          ),
        ),
      ),
    );
    await settleFrames(tester);
  }

  /// The disc drawn behind a day number.
  BoxDecoration discOf(WidgetTester tester, String day) =>
      tester
              .widget<Container>(
                find
                    .ancestor(
                      of: find.text(day),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  /// How many of the day's two half-cells are tinted with the range band.
  int bandHalvesOf(WidgetTester tester, String day) => tester
      .widgetList<ColoredBox>(
        find.descendant(
          of: find
              .ancestor(of: find.text(day), matching: find.byType(InkResponse))
              .first,
          matching: find.byType(ColoredBox),
        ),
      )
      .where((ColoredBox box) => box.color != AppColors.transparent)
      .length;

  testWidgets('marks both ends of the window at once', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(
      tester,
      from: DateTime(2026, 3, 10),
      to: DateTime(2026, 3, 14),
    );

    expect(discOf(tester, '10').color, AppColors.primary);
    expect(discOf(tester, '14').color, AppColors.primary);
    expect(discOf(tester, '12').color, AppColors.transparent);
  });

  testWidgets('bands the days between the ends, half-bands the ends', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(
      tester,
      from: DateTime(2026, 3, 10),
      to: DateTime(2026, 3, 14),
    );

    expect(bandHalvesOf(tester, '12'), 2, reason: 'inside the window');
    expect(bandHalvesOf(tester, '10'), 1, reason: 'start: trailing half only');
    expect(bandHalvesOf(tester, '14'), 1, reason: 'end: leading half only');
    expect(bandHalvesOf(tester, '9'), 0, reason: 'outside the window');
    expect(bandHalvesOf(tester, '15'), 0, reason: 'outside the window');
  });

  testWidgets('the band fills the cell, so a range reads as one block', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(
      tester,
      from: DateTime(2026, 3, 10),
      to: DateTime(2026, 3, 14),
    );

    final Finder cell = find
        .ancestor(of: find.text('12'), matching: find.byType(InkResponse))
        .first;
    final Finder band = find
        .descendant(of: cell, matching: find.byType(ColoredBox))
        .first;

    expect(tester.getSize(band).height, tester.getSize(cell).height);
  });

  testWidgets('draws no band for a single picked day', (
    WidgetTester tester,
  ) async {
    await pumpCalendar(
      tester,
      from: DateTime(2026, 3, 10),
      to: DateTime(2026, 3, 10),
    );

    expect(discOf(tester, '10').color, AppColors.primary);
    expect(bandHalvesOf(tester, '10'), 0);
  });

  testWidgets('days before firstDate do not report a tap', (
    WidgetTester tester,
  ) async {
    final List<DateTime> tapped = <DateTime>[];

    await pumpCalendar(
      tester,
      from: DateTime(2026, 3, 10),
      firstDate: DateTime(2026, 3, 10),
      onDateSelected: tapped.add,
    );

    await tester.tap(find.text('9'));
    await tester.pump();
    expect(tapped, isEmpty);

    await tester.tap(find.text('11'));
    await tester.pump();
    expect(tapped, <DateTime>[DateTime(2026, 3, 11)]);
  });
}
