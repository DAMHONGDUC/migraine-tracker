import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
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
              child: Icon(
                Icons.check_circle_outline,
                size: AppSpacingConstant.r64,
                color: context.colorScheme.primary,
              ),
            ),
            SizedBox(height: AppSpacingConstant.h16),
            Text(l10n.logSavedTitle, style: context.textTheme.headlineSmall),
            SizedBox(height: AppSpacingConstant.h8),
            Text(
              l10n.logSavedSubtitle,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppSpacingConstant.h32),
            OutlinedButton(
              onPressed: () => showAppBottomSheet<void>(
                context,
                isScrollControlled: true,
                builder: (_) => AttackDetailsSheet(attackId: attackId),
              ),
              child: Text(l10n.logAddDetails),
            ),
            SizedBox(height: AppSpacingConstant.h12),
            FilledButton(onPressed: onDone, child: Text(l10n.logDone)),
          ],
        ),
      ),
    );
  }
}
