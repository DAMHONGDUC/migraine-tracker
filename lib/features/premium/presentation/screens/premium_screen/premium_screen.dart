import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../providers.dart';

part 'premium_screen_status_card.dart';

/// What the subscription is right now, and what it includes. Pushed from
/// Settings and from the account screen.
///
/// It is the *status* page — the purchase itself stays on the paywall
/// sheet, so there is one place that sells and one place that reports.
/// Entitlement comes from [hasPremiumProvider] (RevenueCat once wired),
/// never from a flag this app could write.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return SdScaffoldV2(
      title: Text(l10n.premiumScreenTitle, style: AppTextStyle.titleLarge),
      body: SdActionViewV2(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _StatusCard(premium: premium),
            SizedBox(height: SdSpacingConstant.h24),
            Text(
              l10n.premiumScreenIncluded,
              style: AppTextStyle.titleMedium.w600,
            ),
            SizedBox(height: SdSpacingConstant.h12),
            SdBenefitRowV2(
              icon: Icons.notifications_active_outlined,
              title: l10n.paywallBenefitAlerts,
              body: l10n.paywallBenefitAlertsBody,
            ),
            SdBenefitRowV2(
              icon: Icons.show_chart,
              title: l10n.paywallBenefitForecast,
              body: l10n.paywallBenefitForecastBody,
            ),
            SdBenefitRowV2(
              icon: Icons.insights_outlined,
              title: l10n.paywallBenefitInsights,
              body: l10n.paywallBenefitInsightsBody,
            ),
            SdBenefitRowV2(
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.paywallBenefitReport,
              body: l10n.paywallBenefitReportBody,
            ),
            SdBenefitRowV2(
              icon: Icons.bedtime_outlined,
              title: l10n.paywallBenefitSleep,
              body: l10n.paywallBenefitSleepBody,
            ),
          ],
        ),
        actions: <Widget>[
          if (premium)
            // Cancelling and refunds are the store's, not ours — say so instead of a dead button.
            Text(
              l10n.premiumScreenManageNote,
              style: AppTextStyle.bodySmall.secondary,
            )
          else
            SdButtonV2(
              variant: SdButtonVariantV2.primary,
              onPressed: () => NavigationUtils.toPaywall(context, ref),
              label: l10n.premiumUnlock,
            ),
        ],
      ),
    );
  }
}
