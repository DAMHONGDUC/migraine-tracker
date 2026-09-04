import 'package:drift/drift.dart';

/// One pressure reading per day, whether or not an attack happened.
@DataClassName('DailyWeatherRow')
class DailyWeather extends Table {
  /// Local midnight of the day this reading belongs to.
  DateTimeColumn get day => dateTime()();

  DateTimeColumn get capturedAt => dateTime()();
  RealColumn get pressureHpa => real()();
  RealColumn get pressureDelta24hHpa => real()();

  /// The day's humidity and temperature, so the factor map can weigh a muggy day and a temperature swing against the days without one. Null on every row written before v20.
  RealColumn get humidityPercent => real().nullable()();
  RealColumn get temperatureCelsius => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}
