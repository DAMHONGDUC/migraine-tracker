import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/export_date_filter.dart';

/// The date window the export screen's history is filtered to. Holds state
/// only — like `MedicationFiltersController`, there is nothing here that can
/// fail, so nothing to catch.
class ExportFilterController extends Notifier<ExportDateFilter> {
  @override
  ExportDateFilter build() => const ExportDateFilter();

  /// Applies a window, or clears the filter when handed an inactive one.
  void select(ExportDateFilter filter) => state = filter;
}
