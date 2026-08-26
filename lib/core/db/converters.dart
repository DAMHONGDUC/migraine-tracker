import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/attacks/domain/enums/aura_type.dart';
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
/// Aura kinds as a JSON array of enum names, like the head regions below.
///
/// Unknown names are dropped rather than throwing: a row written by a newer
/// build that learned a fifth kind must still open on this one.
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
