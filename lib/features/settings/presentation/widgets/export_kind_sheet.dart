import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_spacing_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/export_kind_label.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/enums/export_kind.dart';

/// Picks what to export. Pops the choice, or null.
///
/// Not the generic filter sheet: there is no "currently selected" kind to
/// pre-check. It is an action picker, so rows carry an icon, not a radio.
///
/// Show it with `ExportKindSheet().show(context)`.
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
              AppSpacingConstant.w24,
              AppSpacingConstant.h4,
              AppSpacingConstant.w24,
              AppSpacingConstant.h12,
            ),
            child: Text(
              context.l10n.exportPickTitle,
              style: AppTextStyle.titleMedium,
            ),
          ),
          for (final ExportKind kind in ExportKind.values)
            _KindTile(kind: kind),
          SizedBox(height: AppSpacingConstant.h8),
        ],
      ),
    );
  }
}

/// One export option. The doctor report is premium: a free user gets the
/// pitch and the paywall instead of a row that would produce nothing.
class _KindTile extends ConsumerWidget {
  const _KindTile({required this.kind});

  final ExportKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (kind.isPremium && !ref.watch(hasPremiumProvider)) {
      return ListTile(
        leading: AppIcon(kind.icon, color: context.colorScheme.onSurfaceVariant),
        title: Text(kind.label(l10n), style: AppTextStyle.bodyLarge),
        subtitle: Text(
          l10n.premiumLockedReport,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        trailing: const PremiumBadge(),
        onTap: () {
          // Close the picker first: the paywall is a sheet too, and two of
          // them stacked is how the user loses track of where they are.
          Navigator.of(context).pop();
          NavigationUtils.toPaywall(context, ref);
        },
      );
    }

    return ListTile(
      leading: AppIcon(kind.icon, color: context.colorScheme.primary),
      title: Text(kind.label(l10n), style: AppTextStyle.bodyLarge),
      onTap: () => Navigator.of(context).pop(kind),
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension ExportKindSheetExt on ExportKindSheet {
  Future<ExportKind?> show(BuildContext context) =>
      showAppBottomSheet<ExportKind>(context, builder: (_) => this);
}
