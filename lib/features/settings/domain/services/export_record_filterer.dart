import '../entities/export_date_filter.dart';
import '../entities/export_record.dart';

/// Narrows the export history to a date window. Pure Dart: the repository
/// streams every record and this decides what the screen lists, the same
/// division `MedicationFilterer` uses for the medications tab.
class ExportRecordFilterer {
  const ExportRecordFilterer();

  /// Records whose local calendar day falls inside [filter], both ends
  /// inclusive. An inactive filter hands [records] straight back.
  List<ExportRecord> apply(
    List<ExportRecord> records,
    ExportDateFilter filter,
  ) {
    if (!filter.isActive) return records;

    final DateTime? from = filter.from == null ? null : _dayOf(filter.from!);
    final DateTime? to = filter.to == null ? null : _dayOf(filter.to!);

    return records.where((ExportRecord record) {
      final DateTime day = _dayOf(record.createdAt.toLocal());

      if (from != null && day.isBefore(from)) return false;
      if (to != null && day.isAfter(to)) return false;

      return true;
    }).toList();
  }

  /// The day a moment belongs to, with the time stripped — an export made at
  /// 23:59 has to count as that day, and comparing instants would drop it from
  /// a window ending on its own date.
  DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
