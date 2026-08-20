import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/attacks/domain/enums/head_region.dart';

/// Stores a list of strings (symptoms, triggers) as a JSON array column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Stores an attack's tapped head areas as a JSON array of [HeadRegion]
/// names. Names, not indices: reordering the enum then cannot silently
/// re-point every stored row at a different part of the head.
///
/// An unknown name is dropped rather than thrown on — it can only come from
/// a newer build's row arriving through sync, and losing one area is a far
/// better failure than a history screen that cannot open at all.
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
