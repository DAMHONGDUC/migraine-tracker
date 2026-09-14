import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_report.dart';
import 'package:migraine_tracker/features/weather/providers.dart';

import '../../helpers/pump_app.dart';

/// A miss is a moment, not a state.
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

  testWidgets('the empty card offers a retry, and it re-reads', (tester) async {
    final PumpedApp app = await pumpApp(tester);

    expect(find.text(unavailable), findsOneWidget);
    final int afterFirst = app.weather.reportCalls;

    app.weather.weatherReport = WeatherReport(
      current: WeatherConditions(
        time: DateTime.now().toUtc(),
        temperatureCelsius: 21,
      ),
      hours: const <WeatherHourly>[],
      days: const <WeatherDaily>[],
    );

    // The tap, not the timer: a failure that is not the network waits forever otherwise.
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.weather.reportCalls, greaterThan(afterFirst));
    expect(find.text('21°'), findsWidgets);

    await finishTest(tester);
  });
}
