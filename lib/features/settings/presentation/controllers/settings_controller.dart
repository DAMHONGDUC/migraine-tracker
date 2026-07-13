import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

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
    final attacks = await _ref.read(attackRepositoryProvider).getAll();
    final medications = await _ref.read(medicationRepositoryProvider).getAll();
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
    await _ref
        .read(exportSinkProvider)
        .share(content: content, filename: filename, mimeType: mime);
  }

  /// Builds the 90-day doctor report and hands the PDF to the share sheet.
  /// [strings] must be the ENGLISH labels (base PDF fonts are Latin-only).
  Future<void> shareDoctorReport(DoctorReportStrings strings) async {
    final attacks = await _ref.read(attackRepositoryProvider).getAll();
    final correlation = _ref.read(correlationEngineProvider).analyze(attacks);
    final now = DateTime.now();
    final bytes = await const DoctorReportBuilder().build(
      attacks: attacks,
      correlation: correlation,
      strings: strings,
      now: now,
    );
    final stamp = DateFormat('yyyy-MM-dd').format(now);
    await _ref
        .read(pdfSharerProvider)
        .share(bytes: bytes, filename: 'baroease_report_$stamp.pdf');
  }

  /// GDPR wipe of all on-device data.
  Future<void> deleteAll() => _ref.read(dataWipeServiceProvider).wipeAll();
}

final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);
