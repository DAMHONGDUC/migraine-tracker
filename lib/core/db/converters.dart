import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a list of strings (symptoms, triggers) as a JSON array column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
