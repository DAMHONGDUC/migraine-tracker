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
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              SdSpacingConstant.h4,
              SdContentPaddingV2.horizontal,
              SdSpacingConstant.h12,
            ),
            child: Text(
              context.l10n.exportPickTitle,
              style: AppTextStyle.titleMedium,
            ),
          ),
          for (final ExportKind kind in ExportKind.values)
            _KindTile(kind: kind),
          SizedBox(height: SdSpacingConstant.h8),
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
      leading: SdIconV2(icon: kind.icon,
                size: AppIconSize.row, color: context.colorScheme.primary),
      title: Text(kind.label(context.l10n), style: AppTextStyle.bodyLarge),
      onTap: () => Navigator.of(context).pop(kind),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level `showX` (CLAUDE.md § Code style).
extension ExportKindSheetExt on ExportKindSheet {
  Future<ExportKind?> show(BuildContext context) =>
      showSdBottomSheetV2<ExportKind>(context, builder: (_) => this);
}
