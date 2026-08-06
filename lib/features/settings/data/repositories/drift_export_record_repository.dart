import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/export_record.dart';
import '../../domain/enums/export_kind.dart';
import '../../domain/repositories/export_record_repository.dart';

/// Drift-backed [ExportRecordRepository].
class DriftExportRecordRepository implements ExportRecordRepository {
  const DriftExportRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ExportRecord>> watchAll() {
    final query = _db.select(_db.exportRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<ExportRecord>> getAll() async {
    final query = _db.select(_db.exportRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final List<ExportRecordRow> rows = await query.get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> insert(ExportRecord record) =>
      _db.into(_db.exportRecords).insertOnConflictUpdate(
        ExportRecordRow(
          id: record.id,
          kind: record.kind.name,
          filename: record.filename,
          filePath: record.filePath,
          sizeBytes: record.sizeBytes,
          createdAt: record.createdAt,
        ),
      );

  @override
  Future<void> deleteById(String id) =>
      (_db.delete(_db.exportRecords)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> deleteAll() => _db.delete(_db.exportRecords).go();

  // Unknown kind = a newer build's row; fall back to json so the screen doesn't crash.
  ExportRecord _toEntity(ExportRecordRow row) => ExportRecord(
    id: row.id,
    kind: ExportKind.values.firstWhere(
      (k) => k.name == row.kind,
      orElse: () => ExportKind.json,
    ),
    filename: row.filename,
    filePath: row.filePath,
    sizeBytes: row.sizeBytes,
    createdAt: row.createdAt,
  );
}
