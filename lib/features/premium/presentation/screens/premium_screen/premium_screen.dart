import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_spacing_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_action_view.dart';
import '../../../../../core/widgets/app_benefit_row.dart';
import '../../../../../core/widgets/buttons/app_button.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_scaffold.dart';
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

    return AppScaffold(
      title: Text(l10n.premiumScreenTitle, style: AppTextStyle.titleLarge),
      body: AppActionView(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _StatusCard(premium: premium),
            SizedBox(height: AppSpacingConstant.h24),
            Text(
              l10n.premiumScreenIncluded,
              style: AppTextStyle.titleMedium.w600,
            ),
            SizedBox(height: AppSpacingConstant.h12),
            AppBenefitRow(
              icon: Icons.notifications_active_outlined,
              title: l10n.paywallBenefitAlerts,
              body: l10n.paywallBenefitAlertsBody,
            ),
            AppBenefitRow(
              icon: Icons.show_chart,
              title: l10n.paywallBenefitForecast,
              body: l10n.paywallBenefitForecastBody,
            ),
            AppBenefitRow(
              icon: Icons.insights_outlined,
              title: l10n.paywallBenefitInsights,
              body: l10n.paywallBenefitInsightsBody,
            ),
            AppBenefitRow(
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.paywallBenefitReport,
              body: l10n.paywallBenefitReportBody,
            ),
            AppBenefitRow(
              icon: Icons.bedtime_outlined,
              title: l10n.paywallBenefitSleep,
              body: l10n.paywallBenefitSleepBody,
            ),
          ],
        ),
        actions: <Widget>[
          if (premium)
            // Cancelling and refunds are the store's, not ours — saying so
            // beats a button that can only open Settings.
            Text(
              l10n.premiumScreenManageNote,
              style: AppTextStyle.bodySmall.secondary,
            )
          else
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: () => NavigationUtils.toPaywall(context, ref),
              label: l10n.premiumUnlock,
            ),
        ],
      ),
    );
  }
}
