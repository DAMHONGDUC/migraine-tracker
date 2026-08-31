import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/export_kind_label.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/export_kind.dart';

/// Picks what to export.
class ExportKindSheet extends StatelessWidget {
  const ExportKindSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Same chrome as every other sheet, and no tick: a tap on a row IS the answer here, so there is nothing left for a commit to do.
    return SdSheetContentV2(
      title: context.l10n.exportPickTitle,
      closeTooltip: context.l10n.commonClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final ExportKind kind in ExportKind.values)
            _KindTile(kind: kind),
        ],
      ),
    );
  }
}

/// One export option. No gate here: the export screen is premium in full (`NavigationUtils.toExport`), so nothing free ever reaches this sheet.
class _KindTile extends StatelessWidget {
  const _KindTile({required this.kind});

  final ExportKind kind;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // The sheet already holds the gutter; ListTile's own 16 on top of it would inset these rows past everything else in the sheet.
      contentPadding: EdgeInsets.zero,
      leading: SdIconV2(icon: kind.icon,
                size: AppIconSize.medium, color: context.colorScheme.primary),
      title: Text(kind.label(context.l10n), style: AppTextStyle.bodyLarge),
      onTap: () => Navigator.of(context).pop(kind),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension ExportKindSheetExt on ExportKindSheet {
  Future<ExportKind?> show(BuildContext context) =>
      showSdBottomSheetV2<ExportKind>(
        context,
        // Without it the route caps near half the screen and SdSheetContentV2's ceiling never applies.
        isScrollControlled: true,
        builder: (_) => this,
      );
}
