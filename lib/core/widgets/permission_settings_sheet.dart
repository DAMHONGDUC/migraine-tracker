import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import '../extensions/context_extensions.dart';
import '../permissions/app_permission_types.dart';
import '../theme/app_icon_constant.dart';
import '../theme/app_icon_size.dart';

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
        icon: AppIconConstant.notificationsOff,
        title: l10n.permissionNotificationTitle,
        body: l10n.permissionNotificationBody,
      ),
      AppPermissionType.location => (
        icon: AppIconConstant.locationOff,
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
          SdContentPaddingV2.horizontal,
          SdSpacingConstant.h8,
          SdContentPaddingV2.horizontal,
          SdSpacingConstant.h16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SdIconV2(
              icon: content.icon,
              size: AppIconSize.hero,
              color: AppColors.primary,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            Text(
              content.title,
              textAlign: TextAlign.center,
              style: AppTextStyle.titleMedium,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              content.body,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h24),
            SdButtonV2(
              variant: SdButtonVariantV2.primary,
              onPressed: () async {
                Navigator.of(context).pop();
                await onOpenSettings();
              },
              label: l10n.permissionOpenSettings,
            ),
            SizedBox(height: SdSpacingConstant.h8),
            SdButtonV2(
              variant: SdButtonVariantV2.text,
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
      showSdBottomSheetV2<void>(context, builder: (_) => this);
}
