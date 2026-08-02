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
        horizontal: SdSpacingV2.w24,
        vertical: SdSpacingV2.h32,
      ),
      child: Column(
        children: <Widget>[
          SdIconV2(
            icon: Icons.inbox_outlined,
            size: SdSpacingV2.r44,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: SdSpacingV2.h12),
          Text(l10n.exportEmptyTitle, style: AppTextStyle.titleSmall),
          SizedBox(height: SdSpacingV2.h8),
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
