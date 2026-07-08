import 'package:drift/drift.dart';

import '../../../core/db/converters.dart';
import '../domain/head_location.dart';

@DataClassName('AttackRow')
class Attacks extends Table {
  TextColumn get id => text()();

  /// Stored as UTC unix timestamp.
  DateTimeColumn get startedAt => dateTime()();

  IntColumn get intensity => integer()();
  TextColumn get location => textEnum<HeadLocation>()();
  TextColumn get medicationName => text().nullable()();
  TextColumn get symptoms => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get triggers => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One optional snapshot per attack; missing while the attack was logged
/// offline, backfilled later.
@DataClassName('WeatherSnapshotRow')
class WeatherSnapshots extends Table {
  TextColumn get attackId =>
      text().references(Attacks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get capturedAt => dateTime()();
  RealColumn get pressureHpa => real()();
  RealColumn get pressureDelta24hHpa => real()();
  RealColumn get humidityPercent => real().nullable()();
  RealColumn get temperatureCelsius => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {attackId};
}
