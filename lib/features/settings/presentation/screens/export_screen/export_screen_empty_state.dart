part of 'export_screen.dart';

/// Shown until the first export exists. Says what the list will hold rather
/// than just "nothing here".
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            Icons.inbox_outlined,
            size: AppSpacingConstant.r44,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: AppSpacingConstant.h12),
          Text(l10n.exportEmptyTitle, style: AppTextStyle.titleSmall),
          SizedBox(height: AppSpacingConstant.h8),
          Text(
            l10n.exportEmptyBody,
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ],
      ),
    );
  }
}
