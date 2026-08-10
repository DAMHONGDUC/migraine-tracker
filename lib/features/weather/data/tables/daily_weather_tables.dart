import 'package:drift/drift.dart';

/// One pressure reading per day, whether or not an attack happened.
///
/// This is the denominator the correlation never had: `WeatherSnapshots` is
/// keyed by `attackId`, so the app knew the weather on attack days and
/// nothing about the days in between. A share computed off attack days alone
/// answers "what share of my attacks fell during drops", never "do drops make
/// me more likely to have one" — and someone in a stormy climate scores high
/// for free.
///
/// **This table must never sync** (hard rule 1): a per-day trail of the
/// weather where the user was is a location history. Every device can rebuild
/// its own from its own position, so there is nothing to gain by uploading it.
@DataClassName('DailyWeatherRow')
class DailyWeather extends Table {
  /// Local midnight of the day this reading belongs to — the identity of a
  /// day as the user lived it, not a UTC one, since "the day I had an attack"
  /// is a local idea.
  DateTimeColumn get day => dateTime()();

  DateTimeColumn get capturedAt => dateTime()();
  RealColumn get pressureHpa => real()();
  RealColumn get pressureDelta24hHpa => real()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}
