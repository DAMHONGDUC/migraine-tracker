import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';
import '../app_permission_types.dart';

/// Shown when a permission is permanently denied — explains why the feature
/// needs it and offers a jump to the OS Settings (the only way to re-enable
/// it). [onOpenSettings] runs after the sheet closes.
///
/// Present it with `PermissionSettingsSheet(...).show(context)` — see
/// [PermissionSettingsSheetExt].
class PermissionSettingsSheet extends StatelessWidget {
  const PermissionSettingsSheet({
    required this.type,
    required this.onOpenSettings,
    super.key,
  });

  final AppPermissionType type;
  final Future<void> Function() onOpenSettings;

  ({IconData icon, String title, String body}) _content(BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      AppPermissionType.notification => (
        icon: Icons.notifications_off_outlined,
        title: l10n.permissionNotificationTitle,
        body: l10n.permissionNotificationBody,
      ),
      AppPermissionType.location => (
        icon: Icons.location_off_outlined,
        title: l10n.permissionLocationTitle,
        body: l10n.permissionLocationBody,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = _content(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacingConstant.w24,
          AppSpacingConstant.h8,
          AppSpacingConstant.w24,
          AppSpacingConstant.h16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppIcon(
              content.icon,
              size: AppSpacingConstant.r44,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacingConstant.h16),
            Text(
              content.title,
              textAlign: TextAlign.center,
              style: AppTextStyle.titleMedium,
            ),
            SizedBox(height: AppSpacingConstant.h8),
            Text(
              content.body,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            SizedBox(height: AppSpacingConstant.h24),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: () async {
                Navigator.of(context).pop();
                await onOpenSettings();
              },
              label: l10n.permissionOpenSettings,
            ),
            SizedBox(height: AppSpacingConstant.h8),
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: l10n.permissionNotNow,
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents [PermissionSettingsSheet] as a bottom sheet. Completes when the
/// sheet is dismissed. Sheets expose their opener as a `.show(context)`
/// extension instead of a top-level `showX` function (see CLAUDE.md § Code
/// style, "Bottom sheets and dialogs").
extension PermissionSettingsSheetExt on PermissionSettingsSheet {
  Future<void> show(BuildContext context) =>
      showAppBottomSheet<void>(context, builder: (_) => this);
}
