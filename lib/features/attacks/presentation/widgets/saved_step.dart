import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/context_extensions.dart';
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
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64.r,
              color: context.colorScheme.primary,
            ),
            SizedBox(height: 16.h),
            Text(l10n.logSavedTitle, style: context.textTheme.headlineSmall),
            SizedBox(height: 8.h),
            Text(
              l10n.logSavedSubtitle,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 32.h),
            OutlinedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AttackDetailsSheet(attackId: attackId),
              ),
              child: Text(l10n.logAddDetails),
            ),
            SizedBox(height: 12.h),
            FilledButton(onPressed: onDone, child: Text(l10n.logDone)),
          ],
        ),
      ),
    );
  }
}
