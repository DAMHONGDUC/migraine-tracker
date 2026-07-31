import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';

/// A tappable feature banner on the dashboard: a tinted leading icon, a title
/// and one supporting line, and a trailing chevron. Used to surface features
/// that live on other tabs (reminders, insights, export).
class DashboardBanner extends StatelessWidget {
  const DashboardBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleChild,
    super.key,
  });

  final IconData icon;

  /// Accent tint for the leading icon badge (its background is this at low
  /// alpha, the glyph is this at full strength).
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Optional rich replacement for the plain [subtitle] Text (e.g. a
  /// [HighlightedTimeText] emphasising a live countdown). When null the plain
  /// [subtitle] is shown.
  final Widget? subtitleChild;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacingConstant.w16),
          child: Row(
            children: [
              Container(
                width: AppSpacingConstant.r44,
                height: AppSpacingConstant.r44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon: icon,
                  size: AppSpacingConstant.r22,
                  color: color,
                ),
              ),
              SizedBox(width: AppSpacingConstant.w16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyle.titleMedium),
                    SizedBox(height: AppSpacingConstant.h2),
                    subtitleChild ??
                        Text(subtitle, style: AppTextStyle.bodySmall.secondary),
                  ],
                ),
              ),
              SizedBox(width: AppSpacingConstant.w8),
              AppIcon(
                icon: Icons.chevron_right,
                size: AppSpacingConstant.r20,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
