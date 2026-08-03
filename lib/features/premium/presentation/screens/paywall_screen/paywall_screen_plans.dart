part of 'paywall_screen.dart';

/// The buyable plans, one selectable row each.
///
/// Prices are the store's own formatted strings — never assembled here, so
/// the currency and its placement always match the customer's storefront.
class _Plans extends StatelessWidget {
  const _Plans({
    required this.offers,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PremiumOffer> offers;
  final String? selectedId;
  final ValueChanged<PremiumOffer> onSelected;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Text(
        context.l10n.paywallNoPlans,
        textAlign: TextAlign.center,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    return Column(
      children: <Widget>[
        for (final PremiumOffer offer in offers) ...<Widget>[
          _PlanRow(
            offer: offer,
            selected: offer.id == selectedId,
            onTap: () => onSelected(offer),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final PremiumOffer offer;
  final bool selected;
  final VoidCallback onTap;

  String _title(AppLocalizations l10n) => switch (offer.period) {
    PremiumPeriod.monthly => l10n.paywallPlanMonthly,
    PremiumPeriod.yearly => l10n.paywallPlanYearly,
    PremiumPeriod.lifetime => l10n.paywallPlanLifetime,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color accent = context.colorScheme.primary;

    return SdPressableScaleV2(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w16,
          vertical: SdSpacingConstant.h12,
        ),
        decoration: BoxDecoration(
          // On the paywall's glass, so the unselected state is a hairline
          // rather than a filled card — a second opaque surface here would
          // flatten the panel it sits on.
          color: selected ? accent.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
          border: Border.all(
            color: selected
                ? accent
                : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            SdIconV2(
              icon: selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: SdSpacingConstant.r20,
              color: selected ? accent : context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_title(l10n), style: AppTextStyle.bodyLarge.w600),
                  if (offer.hasTrial)
                    Text(
                      l10n.paywallPlanTrial(offer.trialDays!),
                      style: AppTextStyle.bodySmall.copyWith(color: accent),
                    ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Text(offer.priceLabel, style: AppTextStyle.bodyLarge.w600),
          ],
        ),
      ),
    );
  }
}
