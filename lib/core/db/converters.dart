import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/attacks/domain/enums/aura_type.dart';
import '../../features/attacks/domain/enums/head_region.dart';
import '../../features/daily_log/domain/enums/daily_factor.dart';

/// Stores a list of strings (symptoms, triggers) as a JSON array column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Stores an attack's tapped head areas as a JSON array of [HeadRegion] names.
class AuraTypeListConverter extends TypeConverter<List<AuraType>, String> {
  const AuraTypeListConverter();

  @override
  List<AuraType> fromSql(String fromDb) {
    final List<dynamic> names = jsonDecode(fromDb) as List<dynamic>;

    return <AuraType>[
      for (final dynamic name in names)
        if (AuraType.values.asNameMap()[name] case final AuraType aura) aura,
    ];
  }

  @override
  String toSql(List<AuraType> value) =>
      jsonEncode(<String>[for (final AuraType a in value) a.name]);
}

class HeadRegionListConverter extends TypeConverter<List<HeadRegion>, String> {
  const HeadRegionListConverter();

  @override
  List<HeadRegion> fromSql(String fromDb) {
    final List<dynamic> names = jsonDecode(fromDb) as List<dynamic>;

    return <HeadRegion>[
      for (final dynamic name in names)
        if (HeadRegion.values.asNameMap()[name] case final HeadRegion region)
          region,
    ];
  }

  @override
  String toSql(List<HeadRegion> value) =>
      jsonEncode(<String>[for (final HeadRegion r in value) r.name]);
}

/// Stores a day's factors as a JSON array of [DailyFactor] names.
class DailyFactorListConverter
    extends TypeConverter<List<DailyFactor>, String> {
  const DailyFactorListConverter();

  @override
  List<DailyFactor> fromSql(String fromDb) {
    final List<dynamic> names = jsonDecode(fromDb) as List<dynamic>;

    return <DailyFactor>[
      for (final dynamic name in names)
        // A factor this build has never heard of is dropped rather than guessed at — a newer device may have written one.
        if (DailyFactor.values.asNameMap()[name] case final DailyFactor factor)
          factor,
    ];
  }

  @override
  String toSql(List<DailyFactor> value) =>
      jsonEncode(<String>[for (final DailyFactor f in value) f.name]);
}
