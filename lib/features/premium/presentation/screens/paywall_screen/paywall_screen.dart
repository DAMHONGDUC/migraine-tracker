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
import '../../../../../core/services/link_launcher_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../auth/providers.dart';
import '../../../domain/entities/premium_offer.dart';
import '../../../domain/enums/premium_period.dart';
import '../../../domain/enums/purchase_error.dart';
import '../../../providers.dart';

part 'paywall_screen_benefits.dart';
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
/// **Buying needs no account** (App Store 5.1.1(v), which submission 1.0(20)
/// was rejected under): the plans, the CTA and Restore are all here signed
/// out, because a subscription to the app's own features is not account-based
/// content. Signing in is offered under the CTA as what it actually buys —
/// the same subscription on the user's other devices — never as the price of
/// buying at all.
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
                // - a sliver that fills what is left, so the pitch sits centred in the free space and still scrolls once a long locale outgrows it
                Expanded(
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              l10n.paywallHeadline,
                              textAlign: TextAlign.center,
                              style: AppTextStyle.titleLarge.w600,
                            ),
                            SizedBox(height: SdSpacingConstant.h20),
                            const _Benefits(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: SdSpacingConstant.h8),
                    _Plans(
                      offers: offers,
                      selectedId: active?.id,
                      onSelected: (PremiumOffer offer) =>
                          selectedId.value = offer.id,
                    ),
                    SizedBox(height: SdSpacingConstant.h12),
                    SdButtonV2(
                      variant: SdButtonVariantV2.primary,
                      // Null while offerings load or when the store has nothing to sell — never a CTA that can only fail.
                      onPressed: active != null
                          ? () {
                              AppAnalytics.logPaywallCtaTapped(
                                signedIn: signedIn,
                              );
                              unawaited(_buy(context, ref, active));
                            }
                          : null,
                      label: l10n.premiumUnlock,
                    ),
                    // App Store 3.1.1 requires a restore path — a reinstall or a second device.
                    SdTextActionV2(
                      label: l10n.paywallRestore,
                      onTap: () => unawaited(_restore(context, ref)),
                    ),
                    // The optional half of 5.1.1(v): a way to register at any
                    // time, saying what registering is worth, under a purchase
                    // that never waited on it.
                    if (!signedIn)
                      SdTextActionV2(
                        label: l10n.paywallWhySignIn,
                        onTap: () =>
                            unawaited(NavigationUtils.toLogin(context)),
                      ),
                    SizedBox(height: SdSpacingConstant.h8),
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
