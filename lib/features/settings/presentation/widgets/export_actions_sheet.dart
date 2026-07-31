import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/entities/export_record.dart';
import '../../domain/enums/export_action.dart';

/// What to do with one export from the history. Pops the chosen action, or
/// null when dismissed.
///
/// Show it with `ExportActionsSheet(record: r).show(context)`.
class ExportActionsSheet extends StatelessWidget {
  const ExportActionsSheet({required this.record, super.key});

  final ExportRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
            child: Text(record.filename, style: AppTextStyle.titleMedium),
          ),
          _ActionTile(
            icon: Icons.ios_share,
            label: l10n.exportShareAction,
            action: ExportAction.share,
          ),
          _ActionTile(
            icon: Icons.download_outlined,
            label: l10n.exportSaveAction,
            action: ExportAction.saveToDevice,
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: l10n.exportDeleteAction,
            action: ExportAction.delete,
            isDestructive: true,
          ),
          SizedBox(height: AppSpacingConstant.h8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.action,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final ExportAction action;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color color = isDestructive
        ? context.colorScheme.error
        : AppColors.primary;

    return ListTile(
      leading: AppIcon(icon: icon, color: color),
      title: Text(
        label,
        style: isDestructive
            ? AppTextStyle.bodyLarge.copyWith(color: color)
            : AppTextStyle.bodyLarge,
      ),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension ExportActionsSheetExt on ExportActionsSheet {
  Future<ExportAction?> show(BuildContext context) =>
      showAppBottomSheet<ExportAction>(context, builder: (_) => this);
}
