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
        horizontal: SdSpacingConstant.w24,
        vertical: SdSpacingConstant.h32,
      ),
      child: Column(
        children: <Widget>[
          SdIconV2(
            icon: Icons.inbox_outlined,
            size: SdSpacingConstant.r44,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(l10n.exportEmptyTitle, style: AppTextStyle.titleSmall),
          SizedBox(height: SdSpacingConstant.h8),
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
