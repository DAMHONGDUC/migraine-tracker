import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import '../theme/app_text_style.dart';
import 'app_icon.dart';

/// Calm, shared empty/error state: a muted icon over a short message.
/// No illustration, no bright colours — photophobia-first (hard rule 3).
class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingConstant.w24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon,
              size: AppSpacingConstant.r64,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppSpacingConstant.h12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
