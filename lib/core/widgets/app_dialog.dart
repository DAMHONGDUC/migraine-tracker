import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';

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
    barrierColor: Colors.black.withValues(alpha: 0.6),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.textTheme.titleLarge),
            if (content != null) ...[SizedBox(height: 16.h), content!],
            if (actions.isNotEmpty) ...[
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) SizedBox(width: 8.w),
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
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20.r, color: scheme.primary),
              SizedBox(width: 12.w),
            ],
            Expanded(child: Text(label, style: context.textTheme.bodyLarge)),
            if (selected != null)
              Icon(
                selected!
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20.r,
                color: selected! ? scheme.primary : scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
