part of 'export_screen.dart';

/// Shown when exports exist but none fall inside the picked date window. A
/// separate state from [_EmptyState] on purpose: "you have none yet" and "your
/// filter hides them all" need different ways out, and the filter pill stays
/// on screen above this one.
class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacingConstant.w24,
        vertical: AppSpacingConstant.h32,
      ),
      child: Column(
        children: <Widget>[
          AppIcon(
            Icons.event_busy_outlined,
            size: AppSpacingConstant.r44,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: AppSpacingConstant.h12),
          Text(l10n.exportFilterNoMatchTitle, style: AppTextStyle.titleSmall),
          SizedBox(height: AppSpacingConstant.h8),
          Text(
            l10n.exportFilterNoMatchBody,
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ],
      ),
    );
  }
}
