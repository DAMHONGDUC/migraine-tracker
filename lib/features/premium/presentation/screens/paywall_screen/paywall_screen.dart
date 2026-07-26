import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/glass/liquid_glass_theme.dart';
import '../../../../auth/providers.dart';

/// The premium pitch. Purchases are NOT wired yet — RevenueCat lands in its
/// own change; until then the CTA explains that instead of pretending.
/// Prices deliberately live with the store products, not hardcoded here.
///
/// Although this is a routed page (deep-linkable, pushed by name), it
/// *presents* as a modal bottom sheet: ~85% tall, slides up from the bottom
/// (see the paywall route's CustomTransitionPage), drag-handle indicator,
/// and an X to dismiss. The area above the sheet stays see-through so the
/// barrier shows the screen underneath.
///
/// Premium gates route through [NavigationUtils.unlockPremium], which signs
/// the user in
/// before pushing this. Deep links skip that, so the CTA checks for itself:
/// signed out, it offers sign-in instead of a purchase.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);

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
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Text(l10n.paywallTitle, style: AppTextStyle.titleLarge.w600),
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const AppIcon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w24,
              AppSpacingConstant.h8,
              AppSpacingConstant.w24,
              // A sheet route, so there is no SafeArea above it — the device
              // inset is taken here, plus the standard gap above it.
              MediaQuery.paddingOf(context).bottom + AppSpacingConstant.h16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Benefits scroll when the sheet is short (small phones);
                // the CTA stays pinned below.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        AppIcon(
                          Icons.storm_outlined,
                          size: AppSpacingConstant.r64,
                          color: context.colorScheme.primary,
                        ),
                        SizedBox(height: AppSpacingConstant.h16),
                        Text(
                          l10n.paywallHeadline,
                          style: AppTextStyle.headlineSmall.w600,
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
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppSpacingConstant.h24),
                    // Signed out, the only honest action here is sign-in:
                    // there is no account for a subscription to attach to.
                    // Signed in, purchases still land with RevenueCat — the
                    // CTA stays inert rather than pretending.
                    AppButton.primary(
                      onPressed: signedIn
                          ? () {}
                          : () => NavigationUtils.toLogin(context),
                      label: signedIn
                          ? l10n.premiumUnlock
                          : l10n.paywallSignInFirst,
                    ),
                    SizedBox(height: AppSpacingConstant.h8),
                    Text(
                      signedIn ? l10n.paywallFreeKeeps : l10n.paywallWhySignIn,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.bodyMedium.secondary,
                    ),
                  ],
                ),
              ],
            ),
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
            // Transparent Material: text/ink need a Material ancestor
            // (without one, Text renders Flutter's yellow double-underline
            // fallback), but it must not paint over the glass.
            child: Material(type: MaterialType.transparency, child: sheet),
          )
        : Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacingConstant.r22),
            ),
            clipBehavior: Clip.antiAlias,
            child: sheet,
          );

    // ~85% tall, pinned to the bottom; the transparent 15% above shows the
    // dimmed screen underneath (the route's barrier handles tap-to-dismiss).
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        widthFactor: 1,
        child: surface,
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

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
          AppIcon(icon, color: context.colorScheme.primary),
          SizedBox(width: AppSpacingConstant.w16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.titleMedium),
                SizedBox(height: AppSpacingConstant.h4),
                Text(body, style: AppTextStyle.bodyMedium.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
