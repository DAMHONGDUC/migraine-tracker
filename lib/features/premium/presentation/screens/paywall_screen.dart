import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass/liquid_glass_theme.dart';

/// The premium pitch. Purchases are NOT wired yet — RevenueCat lands in its
/// own change; until then the CTA explains that instead of pretending.
/// Prices deliberately live with the store products, not hardcoded here.
///
/// Although this is a routed page (deep-linkable, pushed by name), it
/// *presents* as a modal bottom sheet: ~80% tall, slides up from the bottom
/// (see the paywall route's CustomTransitionPage), drag-handle indicator,
/// and an X to dismiss. The area above the sheet stays see-through so the
/// barrier shows the screen underneath.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final sheet = Column(
      children: [
        // Sheet chrome: drag-handle indicator + title row with the X.
        Padding(
          padding: EdgeInsets.only(top: AppSpacingConstant.h12),
          child: Container(
            width: AppSpacingConstant.w32,
            height: AppSpacingConstant.h4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppSpacingConstant.r3),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w24,
            AppSpacingConstant.h4,
            AppSpacingConstant.w8,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.paywallTitle,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w24,
              AppSpacingConstant.h8,
              AppSpacingConstant.w24,
              MediaQuery.paddingOf(context).bottom + AppSpacingConstant.h24,
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
        ),
      ],
    );

    final surface = kLiquidGlassEnabled
        ? LiquidGlass.withOwnLayer(
            settings: kChromeGlass,
            shape: LiquidRoundedSuperellipse(
              borderRadius: AppSpacingConstant.r22,
            ),
            clipBehavior: Clip.antiAlias,
            child: sheet,
          )
        : Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacingConstant.r22),
            ),
            clipBehavior: Clip.antiAlias,
            child: sheet,
          );

    // ~80% tall, pinned to the bottom; the transparent 20% above shows the
    // dimmed screen underneath (the route's barrier handles tap-to-dismiss).
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.8,
        widthFactor: 1,
        child: surface,
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
