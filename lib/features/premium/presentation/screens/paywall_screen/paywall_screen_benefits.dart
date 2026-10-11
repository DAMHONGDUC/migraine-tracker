part of 'paywall_screen.dart';

/// What the subscription buys, framed as one block.
///
/// **Compact, because it shares the screen.** The plans and the CTA are pinned
/// under it and must stay visible while this scrolls.
class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    // Only what Premium adds — everything else is free (`docs/PREMIUM_RULES.md`).
    final List<(IconData, String)> benefits = <(IconData, String)>[
      (AppIconConstant.reminderActive, l10n.paywallBenefitAlerts),
      (AppIconConstant.export, l10n.paywallBenefitExport),
      (AppIconConstant.exportPdf, l10n.paywallBenefitReport),
    ];

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      child: Padding(
        // Bottom is h4, not h12: a compact SdBenefitRowV2 already carries h8 under it, so the last row would otherwise sit 8 low inside the card. h4 + h8 = the h12 above it.
        padding: EdgeInsets.fromLTRB(
          SdSpacingConstant.w16,
          SdSpacingConstant.h12,
          SdSpacingConstant.w16,
          SdSpacingConstant.h4,
        ),
        child: Column(
          children: <Widget>[
            for (final (IconData icon, String title) in benefits)
              SdBenefitRowV2(
                icon: icon,
                title: title,
                density: SdBenefitDensityV2.compact,
              ),
          ],
        ),
      ),
    );
  }
}
