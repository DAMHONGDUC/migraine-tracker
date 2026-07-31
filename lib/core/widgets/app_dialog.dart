import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import 'app_icon.dart';

/// Shows [AppDialog] (or any dialog content) with a calm fade + gentle
/// scale on open, reversed on close (hard rule 3: nothing flashy).
/// Always use this instead of raw [showDialog].
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.barrier,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) => builder(dialogContext),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Base dialog: consistent surface, radius, paddings, and action row.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    this.content,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacingConstant.r20),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w32),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacingConstant.w24,
          AppSpacingConstant.h22,
          AppSpacingConstant.w24,
          AppSpacingConstant.h16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyle.titleLarge),
            if (content != null) ...[
              SizedBox(height: AppSpacingConstant.h16),
              content!,
            ],
            if (actions.isNotEmpty) ...[
              SizedBox(height: AppSpacingConstant.h20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) SizedBox(width: AppSpacingConstant.w8),
                    action,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tappable row inside an [AppDialog] (pickers, option lists).
class AppDialogOption extends StatelessWidget {
  const AppDialogOption({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Non-null shows a radio indicator on the trailing edge.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacingConstant.w8,
          vertical: AppSpacingConstant.h12,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              AppIcon(
                icon: icon!,
                size: AppSpacingConstant.r20,
                color: scheme.primary,
              ),
              SizedBox(width: AppSpacingConstant.w12),
            ],
            Expanded(child: Text(label, style: AppTextStyle.bodyLarge)),
            if (selected != null)
              AppIcon(
                icon: selected!
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: AppSpacingConstant.r20,
                color: selected! ? scheme.primary : scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
