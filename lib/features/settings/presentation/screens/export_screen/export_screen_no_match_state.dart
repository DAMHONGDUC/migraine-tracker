part of 'export_screen.dart';

/// Shown when exports exist but none fall inside the picked date window.
class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SdContentPaddingV2.horizontal,
        vertical: SdSpacingConstant.h32,
      ),
      child: Column(
        children: <Widget>[
          SdIconV2(
            icon: AppIconConstant.noMatch,
            size: AppIconSize.hero,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: SdSpacingConstant.h12),
          Text(l10n.exportFilterNoMatchTitle, style: AppTextStyle.titleSmall),
          SizedBox(height: SdSpacingConstant.h8),
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
