import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// The premium pitch. Purchases are NOT wired yet — RevenueCat lands in its
/// own change; until then the CTA explains that instead of pretending.
/// Prices deliberately live with the store products, not hardcoded here.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      title: Text(l10n.paywallTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacingConstant.w24,
          AppScaffold.bodyTopInset(context) + AppSpacingConstant.h16,
          AppSpacingConstant.w24,
          AppSpacingConstant.w24,
        ),
        children: [
          Icon(
            Icons.storm_outlined,
            size: AppSpacingConstant.r64,
            color: context.colorScheme.primary,
          ),
          SizedBox(height: AppSpacingConstant.h16),
          Text(
            l10n.paywallHeadline,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacingConstant.h24),
          _Benefit(
            icon: Icons.notifications_active_outlined,
            title: l10n.paywallBenefitAlerts,
            body: l10n.paywallBenefitAlertsBody,
          ),
          _Benefit(
            icon: Icons.show_chart,
            title: l10n.paywallBenefitForecast,
            body: l10n.paywallBenefitForecastBody,
          ),
          _Benefit(
            icon: Icons.insights_outlined,
            title: l10n.paywallBenefitInsights,
            body: l10n.paywallBenefitInsightsBody,
          ),
          _Benefit(
            icon: Icons.picture_as_pdf_outlined,
            title: l10n.paywallBenefitReport,
            body: l10n.paywallBenefitReportBody,
          ),
          SizedBox(height: AppSpacingConstant.h16),
          Text(
            l10n.paywallFreeKeeps,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacingConstant.h24),
          FilledButton(
            onPressed: null,
            child: Text(l10n.premiumUnlock),
          ),
          SizedBox(height: AppSpacingConstant.h8),
          Text(
            l10n.paywallComingSoon,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacingConstant.h16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colorScheme.primary),
          SizedBox(width: AppSpacingConstant.w16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textTheme.titleMedium),
                SizedBox(height: AppSpacingConstant.h4),
                Text(
                  body,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
