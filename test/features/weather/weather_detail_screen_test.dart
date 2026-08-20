import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/theme/app_theme.dart';
import 'package:migraine_tracker/core/widgets/weather/weather_card.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

/// The detail is a screen, and the owner's rule for it is that the page never
/// moves: the readings stay put and only the ten days scroll. None of that is
/// visible to a `find.text` assertion, so it is asserted on the scrollables
/// themselves — there must be exactly one, and it must be the day list.
void main() {
  WeatherReport report({int days = WeatherReport.forecastDayCount}) {
    final DateTime start = DateTime.utc(2026, 8, 18);

    return WeatherReport(
      current: WeatherConditions(
        time: start,
        pressureHpa: 1009.2,
        temperatureCelsius: 28.4,
        apparentTemperatureCelsius: 31.2,
        humidityPercent: 74,
        uvIndex: 7,
        condition: WeatherCondition.partlyCloudy,
        windSpeedKph: 12.5,
        visibilityKm: 16,
        daylight: true,
      ),
      hours: <WeatherHourly>[
        for (int i = 0; i < days * 24; i++)
          WeatherHourly(
            time: start.add(Duration(hours: i)),
            pressureHpa: 1009 - i * 0.05,
            humidityPercent: 70,
            windSpeedKph: 11,
            visibilityKm: 15,
          ),
      ],
      days: <WeatherDaily>[
        for (int i = 0; i < days; i++)
          WeatherDaily(
            date: start.add(Duration(days: i)),
            condition: WeatherCondition.rain,
            temperatureMaxCelsius: 31,
            temperatureMinCelsius: 24,
            precipitationChancePercent: 80,
            precipitationAmountMm: 12.5,
            uvIndexMax: 9,
            sunrise: start.add(Duration(days: i, hours: 22)),
            sunset: start.add(Duration(days: i + 1, hours: 11)),
          ),
      ],
    );
  }

  Future<void> pumpScreen(WidgetTester tester, WeatherReport data) async {
    // The design size every `.w`/`.h`/`.sp` scales from, as `pumpApp` pins it.
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? child) => MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            // The home indicator, so the page is measured against the room a
            // real iPhone leaves rather than 34 points it does not have.
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(bottom: 34)),
              child: WeatherDetailScreen(
                args: WeatherDetailArgs(
                  title: 'Weather',
                  data: WeatherCardData.of(data),
                  place: 'Bến Nghé',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('only the day list scrolls, never the page', (tester) async {
    await pumpScreen(tester, report());

    // One scrollable on the screen, and it is the list: anything else means
    // the readings can be scrolled away from under the user.
    expect(find.byType(Scrollable), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position
          .maxScrollExtent,
      greaterThan(0),
      reason: 'ten days in the window means there is something to scroll',
    );
  });

  testWidgets('every reading is named, and the ten days are all listed', (
    tester,
  ) async {
    await pumpScreen(tester, report());

    // The last cell of the grid: if it is built, every reading above it is.
    expect(find.text('Sunset'), findsOneWidget);

    // Scrolling the days to the end moves them and nothing else: the grid's
    // last cell is still on screen, and the tenth day has been built.
    final ScrollableState list = tester.state<ScrollableState>(
      find.byType(Scrollable),
    );

    list.position.jumpTo(list.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(find.text('Sunset'), findsOneWidget, reason: 'the readings moved');
    // 18 Aug 2026 is a Tuesday, so the tenth day is the Thursday after next.
    expect(find.text('Thursday'), findsWidgets);
  });

  testWidgets('picking a day re-reads the grid against it', (tester) async {
    await pumpScreen(tester, report());

    // Day 0 is today, which keeps the live reading: 28°.
    expect(find.text('28°'), findsOneWidget);

    // 18 Aug 2026 is a Tuesday, so the row under today is Wednesday — the
    // FIRST one, because ten days come round to a second of most weekdays.
    await tester.tap(find.text('Wednesday').first);
    await tester.pumpAndSettle();

    // A day that has not happened has no "now", so the headline falls back
    // to that day's low and high.
    expect(find.text('28°'), findsNothing);
    expect(find.text('24° / 31°'), findsOneWidget);
  });
}
