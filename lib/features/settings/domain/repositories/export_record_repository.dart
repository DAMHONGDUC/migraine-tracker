import '../entities/export_record.dart';

/// The export history. Local-only: what someone exported is health-adjacent
/// and never leaves the device (hard rule 1).
abstract interface class ExportRecordRepository {
  /// Newest first — the export screen lists them in that order.
  Stream<List<ExportRecord>> watchAll();

  Future<List<ExportRecord>> getAll();

  Future<void> insert(ExportRecord record);

  Future<void> deleteById(String id);

  Future<void> deleteAll();
}
