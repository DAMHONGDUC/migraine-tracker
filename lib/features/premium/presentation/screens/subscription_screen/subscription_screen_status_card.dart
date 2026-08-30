part of 'subscription_screen.dart';

/// The answer to "am I premium?", stated once, at the top.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SdIconV2(
                  icon: premium ? AppIconConstant.premium : AppIconConstant.locked,
        size: AppIconSize.medium,
                  color: premium ? context.colorScheme.primary : null,
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: Text(
                    premium
                        ? l10n.accountPremiumActive
                        : l10n.accountPremiumFree,
                    style: AppTextStyle.titleMedium.w600,
                  ),
                ),
                if (premium) const PremiumBadge(),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              premium
                  ? l10n.accountPremiumActiveBody
                  : l10n.accountPremiumFreeBody,
              style: AppTextStyle.bodyMedium.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
