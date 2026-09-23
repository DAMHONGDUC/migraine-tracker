part of 'paywall_screen.dart';

/// The buyable plans, side by side, one selectable card each.
class _Plans extends StatelessWidget {
  const _Plans({
    required this.offers,
    required this.isLoading,
    required this.selectedId,
    required this.onSelected,
  });

  /// The shortest a plan card comes out, so the placeholder reserves the same
  /// space and the CTA under it does not jump when the store answers.
  static double get cardHeight => SdSpacingConstant.h96;

  /// What the store offers here: monthly, yearly and lifetime.
  static const int placeholderCards = 3;

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
      return Row(
        children: <Widget>[
          for (int i = 0; i < placeholderCards; i++) ...<Widget>[
            if (i > 0) SizedBox(width: SdSpacingConstant.w8),
            Expanded(child: SdSkeletonV2(height: cardHeight)),
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

    // IntrinsicHeight + stretch: a card whose note wraps lifts its neighbours with it, so the row stays one height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < offers.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: SdSpacingConstant.w8),
            Expanded(
              child: _PlanCard(
                offer: offers[i],
                selected: offers[i].id == selectedId,
                onTap: () => onSelected(offers[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
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

  /// What the price buys: a month, a year, or everything at once.
  String _cadence(AppLocalizations l10n) => switch (offer.period) {
    PremiumPeriod.monthly => l10n.paywallPlanPerMonth,
    PremiumPeriod.yearly => l10n.paywallPlanPerYear,
    PremiumPeriod.lifetime => l10n.paywallPlanOneTime,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color accent = context.colorScheme.primary;
    final Color muted = context.colorScheme.onSurfaceVariant;

    // - SdCardV2 rather than a Container of its own: an accent fill inside an accent hairline is what it already draws for one offer among identical ones. - The check says it a second way, so colour is never the only signal (hard rule 3).
    return SdCardV2(
      onTap: onTap,
      borderColor: selected ? accent : null,
      fillColor: selected ? accent.withValues(alpha: 0.14) : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _Plans.cardHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdSpacingConstant.w8,
            vertical: SdSpacingConstant.h12,
          ),
          child: Column(
            children: <Widget>[
              SdIconV2(
                icon: selected
                    ? AppIconConstant.planSelected
                    : AppIconConstant.planUnselected,
                size: AppIconSize.medium,
                fill: selected ? 1 : 0,
                color: selected ? accent : muted,
              ),
              SizedBox(height: SdSpacingConstant.h8),
              Text(
                _title(l10n),
                style: AppTextStyle.labelLarge.copyWith(
                  color: selected ? accent : muted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SdSpacingConstant.h4),
              // FittedBox, not SdFittedTextV2: that one measures through a LayoutBuilder, which IntrinsicHeight above cannot ask.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  offer.priceLabel,
                  style: AppTextStyle.titleLarge.w600,
                  maxLines: 1,
                ),
              ),
              Text(
                _cadence(l10n),
                style: AppTextStyle.bodySmall.secondary,
                textAlign: TextAlign.center,
              ),
              // The trial sits at the foot, so every card's price lines up with its neighbours'.
              if (offer.hasTrial) ...<Widget>[
                const Spacer(),
                SizedBox(height: SdSpacingConstant.h8),
                // scaleDown: a locale whose trial line outruns a third of the width shrinks rather than ellipsing.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SdTagV2(
                    label: l10n.paywallPlanTrial(offer.trialDays!),
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
