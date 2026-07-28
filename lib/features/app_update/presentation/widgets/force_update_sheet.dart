import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_spacing_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/app_update_config.dart';
import '../../providers.dart';

/// The blocking sheet. There is no way out of it on purpose: no drag
/// handle, no barrier dismiss, and [PopScope] eats the back gesture — the
/// only action is going to the store.
///
/// Show it with `ForceUpdateSheet(config: ...).show(context)`.
class ForceUpdateSheet extends ConsumerWidget {
  const ForceUpdateSheet({required this.config, super.key});

  final PlatformUpdateConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w24,
            AppSpacingConstant.h24,
            AppSpacingConstant.w24,
            AppSpacingConstant.h16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppIcon(
                Icons.system_update_alt,
                size: AppSpacingConstant.r44,
                color: context.colorScheme.primary,
              ),
              SizedBox(height: AppSpacingConstant.h16),
              Text(
                l10n.forceUpdateTitle,
                textAlign: TextAlign.center,
                style: AppTextStyle.titleLarge.w600,
              ),
              SizedBox(height: AppSpacingConstant.h8),
              Text(
                l10n.forceUpdateBody,
                textAlign: TextAlign.center,
                style: AppTextStyle.bodyMedium.secondary,
              ),
              if (config.buildName.isNotEmpty) ...<Widget>[
                SizedBox(height: AppSpacingConstant.h8),
                Text(
                  l10n.forceUpdateVersion(config.buildName),
                  textAlign: TextAlign.center,
                  style: AppTextStyle.labelSmall.secondary,
                ),
              ],
              SizedBox(height: AppSpacingConstant.h24),
              _UpdateButton(label: l10n.forceUpdateCta),
            ],
          ),
        ),
      ),
    );
  }
}

/// Separate widget so a failed launch can flip its own state without
/// rebuilding the sheet around it.
class _UpdateButton extends ConsumerWidget {
  const _UpdateButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      variant: AppButtonVariant.primary,
      label: label,
      icon: Icons.open_in_new,
      onPressed: () async {
        final AppLocalizations l10n = context.l10n;
        final bool opened = await ref
            .read(forceUpdateControllerProvider.notifier)
            .openStore();

        if (!opened && context.mounted) {
          AppSnackBarUtils.error(context, l10n.forceUpdateStoreFailed);
        }
      },
    );
  }
}

/// Sheets expose their opener as `.show(context)`, never a top-level
/// `showX` (CLAUDE.md § Code style).
extension ForceUpdateSheetExt on ForceUpdateSheet {
  Future<void> show(BuildContext context) => showAppBottomSheet<void>(
    context,
    builder: (_) => this,
    dismissible: false,
  );
}
