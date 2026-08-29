import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../providers.dart';

part 'premium_screen_status_card.dart';

/// What the subscription is right now, and what it includes.
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
              icon: AppIconConstant.reminderActive,
              title: l10n.paywallBenefitAlerts,
              body: l10n.paywallBenefitAlertsBody,
            ),
            SdBenefitRowV2(
              icon: AppIconConstant.lineChart,
              title: l10n.paywallBenefitForecast,
              body: l10n.paywallBenefitForecastBody,
            ),
            SdBenefitRowV2(
              icon: AppIconConstant.insights,
              title: l10n.paywallBenefitInsights,
              body: l10n.paywallBenefitInsightsBody,
            ),
            SdBenefitRowV2(
              icon: AppIconConstant.exportPdf,
              title: l10n.paywallBenefitReport,
              body: l10n.paywallBenefitReportBody,
            ),
            SdBenefitRowV2(
              icon: AppIconConstant.sleep,
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
