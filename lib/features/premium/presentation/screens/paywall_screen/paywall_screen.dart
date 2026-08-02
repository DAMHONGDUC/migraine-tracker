import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../../core/analytics/app_analytics.dart';
import '../../../../../core/constants/app_content_padding.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/buttons/app_bar_button.dart';
import '../../../../../core/widgets/app_benefit_row.dart';
import '../../../../../core/widgets/buttons/app_button.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/glass/liquid_glass_theme.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../core/widgets/pressable_scale.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../auth/providers.dart';
import '../../../domain/entities/premium_offer.dart';
import '../../../domain/enums/premium_period.dart';
import '../../../domain/enums/purchase_error.dart';
import '../../../providers.dart';

part 'paywall_screen_plans.dart';

/// The premium pitch, and the only place a purchase is started.
/// Prices deliberately live with the store products, not hardcoded here.
///
/// Although this is a routed page (deep-linkable, pushed by name), it
/// *presents* as a modal bottom sheet: ~85% tall, slides up from the bottom
/// (see the paywall route's CustomTransitionPage), drag-handle indicator,
/// and an X to dismiss. The area above the sheet stays see-through so the
/// barrier shows the screen underneath.
///
/// This one keeps its frosted Liquid Glass surface — the app's sheets are
/// flat opaque panels, the paywall deliberately is not.
///
/// Gates route through [NavigationUtils.unlockPremium], which signs the
/// user in first. Deep links skip that, so the CTA checks for itself.
class PaywallScreen extends HookConsumerWidget {
  const PaywallScreen({super.key});

  /// Localized outcome for a failed purchase or restore. [PurchaseError
  /// .cancelled] never reaches here — the controller swallows it, because
  /// closing Apple's sheet is a decision, not an error.
  String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
    PurchaseException(error: final PurchaseError code) => switch (code) {
      PurchaseError.network => l10n.paywallErrorNetwork,
      PurchaseError.alreadyOwned => l10n.paywallErrorAlreadyOwned,
      PurchaseError.pending => l10n.paywallErrorPending,
      PurchaseError.notAllowed => l10n.paywallErrorNotAllowed,
      // A missing key is a wiring bug the user can do nothing about, so it
      // gets the neutral message and the logs get the detail.
      _ => l10n.paywallErrorGeneric,
    },
    _ => l10n.paywallErrorGeneric,
  };

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    PremiumOffer offer,
  ) async {
    final AppLocalizations l10n = context.l10n;

    try {
      final bool entitled = await ref
          .read(paywallControllerProvider.notifier)
          .purchase(offer);

      if (!context.mounted || !entitled) return;

      AppSnackBarUtils.success(context, l10n.paywallPurchaseDone);
      context.pop();
    } catch (error) {
      if (context.mounted) {
        AppSnackBarUtils.error(context, _errorMessage(l10n, error));
      }
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;

    try {
      final bool restored = await ref
          .read(paywallControllerProvider.notifier)
          .restore();

      if (!context.mounted) return;

      if (!restored) {
        AppSnackBarUtils.info(context, l10n.paywallRestoreNothing);
        return;
      }
      AppSnackBarUtils.success(context, l10n.paywallPurchaseDone);
      context.pop();
    } catch (error) {
      if (context.mounted) {
        AppSnackBarUtils.error(context, _errorMessage(l10n, error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);
    final AsyncValue<List<PremiumOffer>> offersState = ref.watch(
      paywallControllerProvider,
    );
    final List<PremiumOffer> offers = switch (offersState) {
      AsyncData(value: final List<PremiumOffer> value) => value,
      _ => const <PremiumOffer>[],
    };
    final ValueNotifier<String?> selectedId = useState<String?>(null);
    final PremiumOffer? selected = offers
        .where((PremiumOffer o) => o.id == selectedId.value)
        .firstOrNull;
    // Default to the yearly plan when nothing is chosen yet — it is the one
    // the pricing is built around, and an unselected list makes the CTA dead.
    final PremiumOffer? active =
        selected ??
        (offers.isEmpty
            ? null
            : offers.firstWhere(
                (PremiumOffer o) => o.period == PremiumPeriod.yearly,
                orElse: () => offers.first,
              ));

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
                child: AppBarButton(
                  icon: Icons.close,
                  // Already on the sheet's glass: a circle here would nest
                  // one glass layer inside another and read flat.
                  surface: AppBarButtonSurface.none,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppContentPadding.horizontal,
              AppSpacingConstant.h8,
              AppContentPadding.horizontal,
              // A sheet route rather than a screen, but the same rule: it
              // clears the home indicator by the same 16.
              AppContentPadding.bottom(context),
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
                          icon: Icons.storm_outlined,
                          size: AppSpacingConstant.r64,
                          color: context.colorScheme.primary,
                        ),
                        SizedBox(height: AppSpacingConstant.h16),
                        Text(
                          l10n.paywallHeadline,
                          style: AppTextStyle.headlineSmall.w600,
                        ),
                        SizedBox(height: AppSpacingConstant.h24),
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
                        // Plans only once there is an account to attach a
                        // subscription to: showing prices behind a sign-in
                        // wall would invite a tap that cannot complete.
                        if (signedIn) ...<Widget>[
                          SizedBox(height: AppSpacingConstant.h24),
                          _Plans(
                            offers: offers,
                            selectedId: active?.id,
                            onSelected: (PremiumOffer offer) =>
                                selectedId.value = offer.id,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppSpacingConstant.h24),
                    // Signed out there is no account to attach a
                    // subscription to, so the CTA signs in first.
                    AppButton(
                      variant: AppButtonVariant.primary,
                      // Null while the offerings are still loading, and when
                      // the store returned nothing to sell — a CTA that can
                      // only fail is worse than a disabled one.
                      onPressed: !signedIn || active != null
                          ? () {
                              AppAnalytics.logPaywallCtaTapped(
                                signedIn: signedIn,
                              );
                              if (!signedIn) {
                                NavigationUtils.toLogin(context);
                                return;
                              }
                              unawaited(_buy(context, ref, active!));
                            }
                          : null,
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
                    // App Store 3.1.1 requires a restore path for anyone who
                    // already paid — a reinstall or a second device.
                    if (signedIn)
                      AppButton(
                        variant: AppButtonVariant.text,
                        onPressed: () => unawaited(_restore(context, ref)),
                        label: l10n.paywallRestore,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final surface = AppGlass.isSupported
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
