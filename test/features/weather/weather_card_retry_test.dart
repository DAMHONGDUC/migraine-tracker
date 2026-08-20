import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/providers.dart';

import '../../helpers/pump_app.dart';

/// A miss is a moment, not a state.
///
/// The position has not been fixed yet, the anonymous session is still coming
/// up, the callable is cold — and until the retry existed the card kept that
/// null for as long as it stayed on screen, because a completed value is not
/// recomputed just because someone is still looking at it.
void main() {
  const String unavailable = 'Weather is unavailable right now.';

  testWidgets('a failed read heals itself while the card is on screen', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);

    // The first read found nothing.
    expect(find.text(unavailable), findsOneWidget);
    final int afterFirst = app.weather.reportCalls;

    // Whatever was wrong stops being wrong.
    app.weather.weatherReport = WeatherReport(
      current: WeatherConditions(
        time: DateTime.now().toUtc(),
        temperatureCelsius: 18,
      ),
      hours: const <WeatherHourly>[],
      days: const <WeatherDaily>[],
    );

    await tester.pump(weatherRetryDelay + const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.weather.reportCalls, greaterThan(afterFirst));
    expect(find.text(unavailable), findsNothing);
    expect(find.text('18°'), findsWidgets);

    await finishTest(tester);
  });
}
