part of 'paywall_screen.dart';

/// The buyable plans, one selectable row each.
class _Plans extends StatelessWidget {
  const _Plans({
    required this.offers,
    required this.isLoading,
    required this.selectedId,
    required this.onSelected,
  });

  /// How tall a plan row comes out, so the placeholder reserves the same space
  /// and the CTA under it does not jump when the store answers.
  static double get rowHeight => SdSpacingConstant.h64;

  /// What the store offers here: monthly, yearly and lifetime.
  static const int placeholderRows = 3;

  final List<PremiumOffer> offers;

  /// Whether the store has not answered yet. Empty *and* loading is a wait;
  /// empty and settled is a store with nothing to sell, and those are not the
  /// same screen.
  final bool isLoading;

  final String? selectedId;
  final ValueChanged<PremiumOffer> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < placeholderRows; i++) ...<Widget>[
            if (i > 0) SizedBox(height: SdContentPaddingV2.listItemGap),
            SdSkeletonV2(height: rowHeight),
          ],
        ],
      );
    }

    if (offers.isEmpty) {
      // An icon, not a line of prose where the plans should be: a bare sentence there reads as a failure rather than as a state.
      return SdEmptyStateV2(
        icon: AppIconConstant.premium,
        message: context.l10n.paywallNoPlans,
        size: SdEmptyStateSizeV2.compact,
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
                  // The price has no period after it, so the row says why.
                  if (offer.period == PremiumPeriod.lifetime)
                    Text(
                      l10n.paywallPlanOneTime,
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
