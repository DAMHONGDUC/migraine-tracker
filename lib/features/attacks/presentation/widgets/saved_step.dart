import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
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
        padding: EdgeInsets.all(AppSpacingConstant.w24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: AppIcon(
                icon: Icons.check_circle_outline,
                size: AppSpacingConstant.r64,
                color: context.colorScheme.primary,
              ),
            ),
            SizedBox(height: AppSpacingConstant.h16),
            Text(l10n.logSavedTitle, style: AppTextStyle.headlineSmall),
            SizedBox(height: AppSpacingConstant.h8),
            Text(
              l10n.logSavedSubtitle,
              style: AppTextStyle.bodyLarge.secondary,
            ),
            SizedBox(height: AppSpacingConstant.h32),
            AppButton(
              variant: AppButtonVariant.outlined,
              onPressed: () =>
                  AttackDetailsSheet(attackId: attackId).show(context),
              label: l10n.logAddDetails,
            ),
            SizedBox(height: AppSpacingConstant.h12),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: onDone,
              label: l10n.logDone,
            ),
          ],
        ),
      ),
    );
  }
}
