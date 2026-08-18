part of 'paywall_screen.dart';

/// What the subscription buys, framed as one block.
///
/// A card rather than six loose rows on the panel: the pitch is the one thing
/// on this sheet that has to be read before the prices, and a surface of its
/// own is what separates it from the chrome above and the plans below.
/// [SdCardSurfaceV2.elevated] because it sits *on* the paywall's glass — the
/// same step up anything on a card or a sheet takes, and still dark enough
/// for hard rule 3.
class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      child: Padding(
        // Bottom is h4, not h16: every SdBenefitRowV2 already carries h12
        // under it, so the last row would otherwise sit 12 low inside the card.
        padding: EdgeInsets.fromLTRB(
          SdSpacingConstant.w16,
          SdSpacingConstant.h16,
          SdSpacingConstant.w16,
          SdSpacingConstant.h4,
        ),
        child: Column(
          children: <Widget>[
            SdBenefitRowV2(
              icon: Icons.all_inclusive,
              title: l10n.paywallBenefitUnlimited,
            ),
            SdBenefitRowV2(
              icon: Icons.notifications_active_outlined,
              title: l10n.paywallBenefitAlerts,
            ),
            SdBenefitRowV2(
              icon: Icons.show_chart,
              title: l10n.paywallBenefitForecast,
            ),
            SdBenefitRowV2(
              icon: Icons.insights_outlined,
              title: l10n.paywallBenefitInsights,
            ),
            SdBenefitRowV2(
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.paywallBenefitReport,
            ),
            SdBenefitRowV2(
              icon: Icons.bedtime_outlined,
              title: l10n.paywallBenefitSleep,
            ),
          ],
        ),
      ),
    );
  }
}
