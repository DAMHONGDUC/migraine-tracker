import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/export_format.dart';

/// Picks the format for a data export (hard rule 8 — GDPR export stays free
/// forever). Pops the chosen [ExportFormat], or null when dismissed.
///
/// Deliberately not the generic single-choice filter sheet: there is no
/// "currently selected" format to pre-check here. This is an action picker —
/// each row starts an export — so the rows carry a format icon and a line of
/// what you get, not a radio button.
///
/// Present it with `ExportFormatSheet().show(context)` — see
/// [ExportFormatSheetExt].
class ExportFormatSheet extends StatelessWidget {
  const ExportFormatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w24,
              AppSpacingConstant.h4,
              AppSpacingConstant.w24,
              AppSpacingConstant.h12,
            ),
            child: Text(l10n.settingsExport, style: AppTextStyle.titleMedium),
          ),
          _FormatTile(
            icon: Icons.data_object,
            label: l10n.settingsExportJson,
            format: ExportFormat.json,
          ),
          _FormatTile(
            icon: Icons.table_chart_outlined,
            label: l10n.settingsExportCsv,
            format: ExportFormat.csv,
          ),
          SizedBox(height: AppSpacingConstant.h8),
        ],
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.icon,
    required this.label,
    required this.format,
  });

  final IconData icon;
  final String label;
  final ExportFormat format;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(icon, color: context.colorScheme.primary),
      title: Text(label, style: AppTextStyle.bodyLarge),
      onTap: () => Navigator.of(context).pop(format),
    );
  }
}

/// Presents [ExportFormatSheet] and completes with the picked format, or
/// null if dismissed. Sheets expose their opener as a `.show(context)`
/// extension instead of a top-level `showX` function (see CLAUDE.md § Code
/// style, "Bottom sheets and dialogs").
extension ExportFormatSheetExt on ExportFormatSheet {
  Future<ExportFormat?> show(BuildContext context) =>
      showAppBottomSheet<ExportFormat>(context, builder: (_) => this);
}
