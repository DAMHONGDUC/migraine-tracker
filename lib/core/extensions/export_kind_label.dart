import 'package:flutter/material.dart';

import '../../features/settings/domain/enums/export_kind.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/app_icon_constant.dart';

/// User-facing label and glyph for [ExportKind], shared by the export
/// picker and the history rows so the two can never disagree.
extension ExportKindLabel on ExportKind {
  String label(AppLocalizations l10n) => switch (this) {
    ExportKind.json => l10n.settingsExportJson,
    ExportKind.csv => l10n.settingsExportCsv,
    ExportKind.pdf => l10n.settingsDoctorReport,
  };

  IconData get icon => switch (this) {
    ExportKind.json => AppIconConstant.exportJson,
    ExportKind.csv => AppIconConstant.exportCsv,
    ExportKind.pdf => AppIconConstant.exportPdf,
  };
}
