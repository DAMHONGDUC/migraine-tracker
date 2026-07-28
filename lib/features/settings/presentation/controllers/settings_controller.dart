import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../attacks/providers.dart';
import '../../../insights/domain/services/doctor_report_builder.dart';
import '../../../insights/providers.dart';
import '../../../medications/providers.dart';
import '../../domain/enums/export_format.dart';
import '../../providers.dart';

/// Orchestrates the settings actions (export, wipe) so the widget only shows
/// dialogs and delegates — no data access or serialization in the UI layer.
class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  /// Serializes all data in [format] and hands it to the share sheet.
  Future<void> export(ExportFormat format) async {
    try {
      final attacks = await _ref.read(attackRepositoryProvider).getAll();
      final medications = await _ref
          .read(medicationRepositoryProvider)
          .getAll();
      final service = _ref.read(dataExportServiceProvider);
      final now = DateTime.now();
      final stamp = DateFormat('yyyy-MM-dd').format(now);
      final (content, filename, mime) = switch (format) {
        ExportFormat.json => (
          service.toJson(attacks, medications, exportedAt: now),
          'baroease_export_$stamp.json',
          'application/json',
        ),
        ExportFormat.csv => (
          service.toCsv(attacks),
          'baroease_export_$stamp.csv',
          'text/csv',
        ),
      };

      AppLogger.action('Export data', format.name);
      AppAnalytics.logDataExported(
        format: format.name,
        attackCount: attacks.length,
      );
      await _ref
          .read(exportSinkProvider)
          .share(content: content, filename: filename, mimeType: mime);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Export data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Builds the 90-day doctor report and hands the PDF to the share sheet.
  /// Loads the bundled Noto Sans faces the PDF renders with. Cached for the
  /// process lifetime — the report is built rarely but re-reading 1MB of TTF
  /// each time is wasteful.
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  Future<(pw.Font, pw.Font)> _reportFonts() async {
    _regularFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    _boldFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    return (_regularFont!, _boldFont!);
  }

  /// [strings] are localized — the bundled font covers Vietnamese.
  Future<void> shareDoctorReport(DoctorReportStrings strings) async {
    try {
      final attacks = await _ref.read(attackRepositoryProvider).getAll();
      final correlation = _ref.read(correlationEngineProvider).analyze(attacks);
      final (regular, bold) = await _reportFonts();
      final now = DateTime.now();
      final bytes = await const DoctorReportBuilder().build(
        attacks: attacks,
        correlation: correlation,
        strings: strings,
        now: now,
        regularFont: regular,
        boldFont: bold,
      );
      final stamp = DateFormat('yyyy-MM-dd').format(now);

      AppLogger.action('Share doctor report (PDF)');
      AppAnalytics.logDoctorReportShared(attackCount: attacks.length);
      await _ref
          .read(pdfSharerProvider)
          .share(bytes: bytes, filename: 'baroease_report_$stamp.pdf');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Share doctor report failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// GDPR wipe of all on-device data.
  Future<void> deleteAll() async {
    AppLogger.action('Delete all data (GDPR wipe)');
    AppAnalytics.logDataWiped();
    try {
      await _ref.read(dataWipeServiceProvider).wipeAll();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Delete all data failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
