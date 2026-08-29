import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import 'attack_details_sheet.dart';

/// Confirmation after the attack is saved. Calm, static — no flashing.
class SavedStep extends StatelessWidget {
  const SavedStep({required this.attackId, required this.onDone, super.key});

  final String attackId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV2.horizontal,
          vertical: SdSpacingConstant.h24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: SdIconV2(
                icon: AppIconConstant.saved,
                size: AppIconSize.display,
                color: context.colorScheme.primary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h16),
            Text(l10n.logSavedTitle, style: AppTextStyle.headlineSmall),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              l10n.logSavedSubtitle,
              style: AppTextStyle.bodyLarge.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h32),
            SdButtonV2(
              variant: SdButtonVariantV2.outlined,
              onPressed: () =>
                  AttackDetailsSheet(attackId: attackId).show(context),
              label: l10n.logAddDetails,
            ),
            SizedBox(height: SdSpacingConstant.h12),
            SdButtonV2(
              variant: SdButtonVariantV2.primary,
              onPressed: onDone,
              label: l10n.logDone,
            ),
          ],
        ),
      ),
    );
  }
}
