import 'package:meta/meta.dart';

/// The date window the export history is narrowed to.
@immutable
class ExportDateFilter {
  const ExportDateFilter({this.from, this.to});

  /// Puts the two bounds in order. Someone picking the later day first would otherwise hand over an inverted window, which matches nothing.
  factory ExportDateFilter.ordered({DateTime? from, DateTime? to}) {
    if (from != null && to != null && from.isAfter(to)) {
      return ExportDateFilter(from: to, to: from);
    }

    return ExportDateFilter(from: from, to: to);
  }

  final DateTime? from;
  final DateTime? to;

  /// Whether this window hides anything at all.
  bool get isActive => from != null || to != null;
}
