part of 'premium_screen.dart';

/// The answer to "am I premium?", stated once, at the top.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingV2.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SdIconV2(
                  icon: premium ? Icons.workspace_premium : Icons.lock_outline,
                  color: premium ? context.colorScheme.primary : null,
                ),
                SizedBox(width: SdSpacingV2.w8),
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
            SizedBox(height: SdSpacingV2.h8),
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
