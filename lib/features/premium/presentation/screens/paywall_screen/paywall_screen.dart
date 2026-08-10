import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:system_design/index.dart';

import '../../../../../core/analytics/app_analytics.dart';
import '../../../../../core/constants/legal_url_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../auth/providers.dart';
import '../../../domain/entities/premium_offer.dart';
import '../../../domain/enums/premium_period.dart';
import '../../../domain/enums/purchase_error.dart';
import '../../../providers.dart';

part 'paywall_screen_legal_links.dart';
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

  /// Messages land at the top. The sheet covers the bottom ~87% of the
  /// screen, so a card at the usual edge would sit on the plans the user is
  /// still reading — or, worse, under the sheet's own surface.
  static const SdSnackBarPlacementV2 _placement = SdSnackBarPlacementV2.top;

  /// Localized outcome for a failed purchase or restore. [PurchaseError
  /// .cancelled] never reaches here — the controller swallows it, because
  /// closing Apple's sheet is a decision, not an error.
  String _errorMessage(AppLocalizations l10n, Object error) => switch (error) {
    PurchaseException(error: final PurchaseError code) => switch (code) {
      PurchaseError.network => l10n.paywallErrorNetwork,
      PurchaseError.alreadyOwned => l10n.paywallErrorAlreadyOwned,
      PurchaseError.pending => l10n.paywallErrorPending,
      PurchaseError.notAllowed => l10n.paywallErrorNotAllowed,
      // A missing key is a wiring bug — neutral message for the user, detail in the logs.
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

      SdSnackBarUtilsV2.success(
        context,
        l10n.paywallPurchaseDone,
        placement: _placement,
      );
      context.pop();
    } catch (error) {
      if (context.mounted) {
        SdSnackBarUtilsV2.error(
          context,
          _errorMessage(l10n, error),
          placement: _placement,
        );
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
        SdSnackBarUtilsV2.info(
          context,
          l10n.paywallRestoreNothing,
          placement: _placement,
        );
        return;
      }
      SdSnackBarUtilsV2.success(
        context,
        l10n.paywallPurchaseDone,
        placement: _placement,
      );
      context.pop();
    } catch (error) {
      if (context.mounted) {
        SdSnackBarUtilsV2.error(
          context,
          _errorMessage(l10n, error),
          placement: _placement,
        );
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
    // Default to the yearly plan when nothing is chosen — an unselected list leaves the CTA dead.
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
          padding: EdgeInsets.only(top: SdSpacingConstant.h12),
          child: Container(
            width: SdSpacingConstant.w32,
            height: SdSpacingConstant.h4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(SdSpacingConstant.r3),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            SdContentPaddingV2.horizontal,
            SdSpacingConstant.h4,
            SdSpacingConstant.w8,
            0,
          ),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Text(l10n.paywallTitle, style: AppTextStyle.titleLarge.w600),
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: SdAppBarButtonV2(
                  icon: Icons.close,
                  // Already on the sheet's glass: a circle here would nest glass inside glass.
                  surface: SdAppBarButtonSurfaceV2.none,
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
              SdContentPaddingV2.horizontal,
              SdSpacingConstant.h8,
              SdContentPaddingV2.horizontal,
              // A sheet route rather than a screen, but the same rule: clears the home indicator by 16.
              SdContentPaddingV2.bottom(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // - only the pitch scrolls; the plans and CTA stay pinned so what the user buys is never under the fold
                // - benefit titles only — five two-line rows pushed the prices off the sheet; full descriptions live on PremiumScreen
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SdIconV2(
                          icon: Icons.storm_outlined,
                          size: SdSpacingConstant.r64,
                          color: context.colorScheme.primary,
                        ),
                        SizedBox(height: SdSpacingConstant.h16),
                        Text(
                          l10n.paywallHeadline,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.titleLarge.w600,
                        ),
                        SizedBox(height: SdSpacingConstant.h20),
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
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Plans only with an account: prices behind a sign-in wall invite a tap that can't complete.
                    if (signedIn) ...<Widget>[
                      SizedBox(height: SdSpacingConstant.h8),
                      _Plans(
                        offers: offers,
                        selectedId: active?.id,
                        onSelected: (PremiumOffer offer) =>
                            selectedId.value = offer.id,
                      ),
                    ],
                    SizedBox(height: SdSpacingConstant.h12),
                    // Signed out there is no account to subscribe to, so the CTA signs in first.
                    SdButtonV2(
                      variant: SdButtonVariantV2.primary,
                      // Null while offerings load or when the store has nothing to sell — never a CTA that can only fail.
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
                    // App Store 3.1.1 requires a restore path — a reinstall or a second device.
                    if (signedIn)
                      SdButtonV2(
                        variant: SdButtonVariantV2.text,
                        onPressed: () => unawaited(_restore(context, ref)),
                        label: l10n.paywallRestore,
                      ),
                    SizedBox(height: SdSpacingConstant.h12),
                    // App Store 3.1.2 requires these in the binary too, not
                    // only in the listing's metadata.
                    const _LegalLinks(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final surface = SdGlassV2.isSupported
        ? LiquidGlass.withOwnLayer(
            settings: kChromeGlass,
            shape: LiquidRoundedSuperellipse(
              borderRadius: SdSpacingConstant.r22,
            ),
            clipBehavior: Clip.antiAlias,
            // Transparent Material: Text needs a Material ancestor, but this one must not paint over the glass.
            child: Material(type: MaterialType.transparency, child: sheet),
          )
        : Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SdSpacingConstant.r22),
            ),
            clipBehavior: Clip.antiAlias,
            child: sheet,
          );

    // ~94% tall, pinned to the bottom; the transparent 15% above shows the dimmed screen underneath.
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.94,
        widthFactor: 1,
        child: surface,
      ),
    );
  }
}
