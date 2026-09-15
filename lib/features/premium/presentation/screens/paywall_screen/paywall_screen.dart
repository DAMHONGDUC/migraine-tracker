import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/analytics/app_analytics.dart';
import '../../../../../core/constants/legal_url_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/services/link_launcher_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icon_constant.dart';
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
class PaywallScreen extends HookConsumerWidget {
  const PaywallScreen({super.key});

  /// Messages land at the top.
  static const SdSnackBarPlacementV2 _placement = SdSnackBarPlacementV2.top;

  /// Localized outcome for a failed purchase or restore.
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
    ValueNotifier<bool> busy,
  ) async {
    if (busy.value) return;

    busy.value = true;

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
    } finally {
      // The hook is gone once the sheet pops, and writing to it then throws.
      if (context.mounted) busy.value = false;
    }
  }

  /// A store call takes seconds with nothing on screen to show for it, so the guard is not a nicety: a second tap ran a second restore, and both popped when they landed — the second one taking the screen under the paywall with it.
  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> busy,
  ) async {
    if (busy.value) return;

    busy.value = true;

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
    } finally {
      if (context.mounted) busy.value = false;
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
    // One flag for both store flows: while either is in flight neither control accepts a tap.
    final ValueNotifier<bool> busy = useState<bool>(false);
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
                  icon: AppIconConstant.close,
                  // Bare on the panel: the sheet chrome carries no surface of its own.
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Keep plans and the purchase action visible while the pitch scrolls. The pitch is the only part that gives: headline + benefits are 49px taller than an iPhone 15 leaves for them, and a Column that cannot scroll answers that with the striped overflow bar rather than by hiding a benefit.
                Expanded(
                  child: SingleChildScrollView(
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
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: SdSpacingConstant.h8),
                    _Plans(
                      offers: offers,
                      isLoading: offersState.isLoading,
                      selectedId: active?.id,
                      onSelected: (PremiumOffer offer) =>
                          selectedId.value = offer.id,
                    ),
                    SizedBox(height: SdSpacingConstant.h12),
                    SdButtonV2(
                      variant: SdButtonVariantV2.primary,
                      // The spinner is the only thing on screen saying the tap landed: a store call runs for seconds with nothing else to show for it.
                      loading: busy.value,
                      // Null while offerings load or when the store has nothing to sell — never a CTA that can only fail.
                      onPressed: active != null
                          ? () {
                              AppAnalytics.logPaywallCtaTapped(
                                signedIn: signedIn,
                              );
                              unawaited(_buy(context, ref, active, busy));
                            }
                          : null,
                      label: l10n.premiumUnlock,
                    ),
                    SizedBox(height: SdSpacingConstant.h8),
                    // App Store 3.1.1 requires a restore path — a reinstall or a second device.
                    SdTextActionV2(
                      label: l10n.paywallRestore,
                      // Null while a store call runs: the control greys out, which is the only thing on screen saying the tap landed.
                      onTap: busy.value
                          ? null
                          : () => unawaited(_restore(context, ref, busy)),
                    ),
                    // The optional half of 5.1.1(v): a way to register at any time, saying what registering is worth, under a purchase that never waited on it.
                    if (!signedIn)
                      SdTextActionV2(
                        label: l10n.paywallWhySignIn,
                        onTap: () =>
                            unawaited(NavigationUtils.toLogin(context)),
                      ),
                    SizedBox(height: SdSpacingConstant.h8),
                    // App Store 3.1.2 requires these in the binary too, not only in the listing's metadata.
                    const _LegalLinks(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final Widget surface = Material(
      // The app's modal colour, a step darker than the card colour this wore: the cards it holds only read as cards while what is under them is darker than they are.
      color: AppColors.surfaceModal,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SdSpacingConstant.r22),
      ),
      clipBehavior: Clip.antiAlias,
      child: sheet,
    );

    // ~90% tall, pinned to the bottom; the transparent 15% above shows the dimmed screen underneath.
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        widthFactor: 1,
        child: surface,
      ),
    );
  }
}
