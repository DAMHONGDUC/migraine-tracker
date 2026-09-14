import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_date_filter.dart';
import 'package:migraine_tracker/features/settings/domain/entities/export_record.dart';
import 'package:migraine_tracker/features/settings/domain/enums/export_kind.dart';
import 'package:migraine_tracker/features/settings/domain/services/export_record_filterer.dart';

/// A record made at [local] on the device's own clock, stored in UTC like the real thing.
ExportRecord recordAt(DateTime local) => ExportRecord(
  id: local.toIso8601String(),
  kind: ExportKind.json,
  filename: 'export.json',
  filePath: '/tmp/export.json',
  sizeBytes: 10,
  createdAt: local.toUtc(),
);

void main() {
  const ExportRecordFilterer filterer = ExportRecordFilterer();

  final ExportRecord march10 = recordAt(DateTime(2026, 3, 10, 9));
  final ExportRecord march12Late = recordAt(DateTime(2026, 3, 12, 23, 59));
  final ExportRecord march20 = recordAt(DateTime(2026, 3, 20, 14));
  final List<ExportRecord> all = <ExportRecord>[march10, march12Late, march20];

  test('an inactive filter keeps every record', () {
    expect(filterer.apply(all, const ExportDateFilter()), all);
  });

  test('both ends are inclusive, on the local calendar day', () {
    final List<ExportRecord> kept = filterer.apply(
      all,
      ExportDateFilter(from: DateTime(2026, 3, 10), to: DateTime(2026, 3, 12)),
    );

    // The 23:59 export belongs to the 12th: comparing instants against midnight would drop it from a window that ends on its own day.
    expect(kept, <ExportRecord>[march10, march12Late]);
  });

  test('only a from is everything since, only a to is everything up to', () {
    expect(
      filterer.apply(all, ExportDateFilter(from: DateTime(2026, 3, 12))),
      <ExportRecord>[march12Late, march20],
    );
    expect(
      filterer.apply(all, ExportDateFilter(to: DateTime(2026, 3, 10))),
      <ExportRecord>[march10],
    );
  });

  test('a window matching nothing comes back empty, not unfiltered', () {
    final List<ExportRecord> kept = filterer.apply(
      all,
      ExportDateFilter(from: DateTime(2026, 4), to: DateTime(2026, 4, 30)),
    );

    expect(kept, isEmpty);
  });

  test('ordered() swaps bounds picked back to front', () {
    final ExportDateFilter filter = ExportDateFilter.ordered(
      from: DateTime(2026, 3, 20),
      to: DateTime(2026, 3, 10),
    );

    expect(filter.from, DateTime(2026, 3, 10));
    expect(filter.to, DateTime(2026, 3, 20));
    expect(filterer.apply(all, filter), all);
  });

  test('isActive says whether anything is hidden', () {
    expect(const ExportDateFilter().isActive, isFalse);
    expect(ExportDateFilter(from: DateTime(2026, 3, 10)).isActive, isTrue);
    expect(ExportDateFilter(to: DateTime(2026, 3, 10)).isActive, isTrue);
  });
}
