import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/providers.dart';
import '../../../insights/domain/services/doctor_report_builder.dart';
import '../../../insights/providers.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/providers.dart';
import '../../domain/entities/export_record.dart';
import '../../domain/enums/export_kind.dart';
import '../../domain/services/export_file_store.dart';
import '../../providers.dart';

/// Owns the export screen's actions: producing an export, and acting on one
/// that already exists. Every export is written to disk and recorded, so the
/// history can re-share or save it later without rebuilding the file.
class ExportController {
  const ExportController(this._ref);

  final Ref _ref;

  static const Uuid _uuid = Uuid();

  /// Timestamped to the second: two exports on the same day must not
  /// overwrite each other's file.
  static final DateFormat _stampFormat = DateFormat('yyyy-MM-dd_HHmmss');

  /// Builds [kind], stores it, and records it in the history.
  ///
  /// [reportStrings] is required for [ExportKind.pdf] — the doctor report is
  /// localized, and l10n lives in the widget layer.
  Future<ExportRecord> create(
    ExportKind kind, {
    DoctorReportStrings? reportStrings,
  }) async {
    AppLogger.action('Create export', kind.name);
    try {
      final DateTime now = DateTime.now();
      final List<Attack> attacks = await _ref
          .read(attackRepositoryProvider)
          .getAll();
      final Uint8List bytes = switch (kind) {
        ExportKind.json => await _jsonBytes(attacks, now),
        ExportKind.csv => _csvBytes(attacks),
        ExportKind.pdf => await _pdfBytes(attacks, reportStrings, now),
      };
      final String filename = _filename(kind, now);
      final StoredExportFile stored = await _ref
          .read(exportFileStoreProvider)
          .write(filename: filename, bytes: bytes);
      final ExportRecord record = ExportRecord(
        id: _uuid.v4(),
        kind: kind,
        filename: filename,
        filePath: stored.path,
        sizeBytes: stored.sizeBytes,
        createdAt: now.toUtc(),
      );

      await _ref.read(exportRecordRepositoryProvider).insert(record);
      _logCreated(kind, attacks.length);

      return record;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Create export failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Hands an existing export to the system share sheet.
  Future<void> share(ExportRecord record) async {
    AppLogger.action('Share export', record.kind.name);
    AppAnalytics.logExportShared(format: record.kind.name);
    try {
      await _ref
          .read(exportSharerProvider)
          .shareFile(path: record.filePath, mimeType: record.kind.mimeType);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Share export failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Copies an existing export wherever the user picks. False means they
  /// dismissed the picker — the caller shows nothing.
  Future<bool> saveToDevice(ExportRecord record) async {
    AppLogger.action('Save export to device', record.kind.name);
    try {
      final bool saved = await _ref
          .read(fileSaverProvider)
          .save(sourcePath: record.filePath, filename: record.filename);

      if (saved) AppAnalytics.logExportSavedToDevice(format: record.kind.name);

      return saved;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Save export to device failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Removes the row and the file behind it.
  Future<void> delete(ExportRecord record) async {
    AppLogger.action('Delete export', record.kind.name);
    AppAnalytics.logExportDeleted();
    try {
      await _ref.read(exportFileStoreProvider).delete(record.filePath);
      await _ref.read(exportRecordRepositoryProvider).deleteById(record.id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Delete export failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Whether the file a row points at is still there. A restore or a manual
  /// clean-up can take it out from under us.
  Future<bool> fileExists(ExportRecord record) =>
      _ref.read(exportFileStoreProvider).exists(record.filePath);

  Future<Uint8List> _jsonBytes(List<Attack> attacks, DateTime now) async {
    final List<Medication> medications = await _ref
        .read(medicationRepositoryProvider)
        .getAll();

    return utf8.encode(
      _ref
          .read(dataExportServiceProvider)
          .toJson(attacks, medications, exportedAt: now),
    );
  }

  Uint8List _csvBytes(List<Attack> attacks) =>
      utf8.encode(_ref.read(dataExportServiceProvider).toCsv(attacks));

  Future<Uint8List> _pdfBytes(
    List<Attack> attacks,
    DoctorReportStrings? strings,
    DateTime now,
  ) async {
    if (strings == null) {
      throw ArgumentError.notNull('reportStrings');
    }
    final correlation = _ref.read(correlationEngineProvider).analyze(attacks);
    final (pw.Font regular, pw.Font bold) = await _reportFonts();

    return const DoctorReportBuilder().build(
      attacks: attacks,
      correlation: correlation,
      strings: strings,
      now: now,
      regularFont: regular,
      boldFont: bold,
    );
  }

  String _filename(ExportKind kind, DateTime now) {
    final String stamp = _stampFormat.format(now);
    final String prefix = kind == ExportKind.pdf
        ? 'baroease_report'
        : 'baroease_export';

    return '${prefix}_$stamp.${kind.fileExtension}';
  }

  // Attack count only — never what was in them (hard rule 1).
  void _logCreated(ExportKind kind, int attackCount) {
    if (kind == ExportKind.pdf) {
      AppAnalytics.logDoctorReportShared(attackCount: attackCount);
      return;
    }
    AppAnalytics.logDataExported(format: kind.name, attackCount: attackCount);
  }

  /// The bundled Noto Sans faces the PDF renders with, cached for the process
  /// lifetime — the report is built rarely, but re-reading 1MB of TTF each
  /// time is wasteful.
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  Future<(pw.Font, pw.Font)> _reportFonts() async {
    _regularFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/noto_sans/NotoSans-Regular.ttf'),
    );
    _boldFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/noto_sans/NotoSans-Bold.ttf'),
    );

    return (_regularFont!, _boldFont!);
  }
}
