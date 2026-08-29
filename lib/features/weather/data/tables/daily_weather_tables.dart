import 'package:drift/drift.dart';

/// One pressure reading per day, whether or not an attack happened.
@DataClassName('DailyWeatherRow')
class DailyWeather extends Table {
  /// Local midnight of the day this reading belongs to.
  DateTimeColumn get day => dateTime()();

  DateTimeColumn get capturedAt => dateTime()();
  RealColumn get pressureHpa => real()();
  RealColumn get pressureDelta24hHpa => real()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}
