part of 'paywall_screen.dart';

/// The buyable plans, one selectable row each.
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
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color accent = context.colorScheme.primary;

    // - SdCardV2 rather than a Container of its own: an accent fill inside an accent hairline is what it already draws for one offer among identical ones. - The radio glyph is gone: the tint and the edge said the same thing twice.
    return SdCardV2(
      onTap: onTap,
      borderColor: selected ? accent : null,
      fillColor: selected ? accent.withValues(alpha: 0.14) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w16,
          vertical: SdSpacingConstant.h12,
        ),
        child: Row(
          children: <Widget>[
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
