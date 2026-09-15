import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../core/theme/app_text_style.dart';
import '../../features/premium/providers.dart';
import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import '../theme/app_icon_constant.dart';
import '../theme/app_icon_size.dart';
import 'settings_tile.dart';

/// Renders [child] for premium users, and a locked pitch otherwise.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    required this.lockedMessage,
    required this.child,
    this.lockedIcon = AppIconConstant.locked,
    super.key,
  });

  final String lockedMessage;
  final IconData lockedIcon;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasPremiumProvider)) return child;
    return _LockedCard(message: lockedMessage, icon: lockedIcon);
  }
}

/// The locked pitch WITHOUT a card around it: the glyph and the badge, what premium would show here, and the way to get it.
class PremiumLockedBody extends ConsumerWidget {
  const PremiumLockedBody({
    required this.message,
    this.icon = AppIconConstant.locked,
    super.key,
  });

  /// Already localized: what premium would show in this slot.
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SdIconV2(
              icon: icon,
              size: AppIconSize.medium,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: SdSpacingConstant.w8),
            const PremiumBadge(),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Text(message, style: AppTextStyle.bodyMedium),
        SizedBox(height: SdSpacingConstant.h12),
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PremiumUnlockButton(),
        ),
      ],
    );
  }
}

/// The app's one Unlock button, and it takes no options.
class PremiumUnlockButton extends ConsumerWidget {
  const PremiumUnlockButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdButtonV2(
      variant: SdButtonVariantV2.primary,
      size: SdButtonSizeV2.small,
      compact: true,
      onPressed: () => NavigationUtils.toPaywall(context, ref),
      label: context.l10n.premiumUnlock,
    );
  }
}

/// The smallest locked state there is: one line saying what premium would show here, and the button that gets it.
class PremiumUnlockPrompt extends ConsumerWidget {
  const PremiumUnlockPrompt({required this.message, super.key});

  /// Already localized: what premium would show in this slot.
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(message, style: AppTextStyle.bodyMedium.secondary),
        SizedBox(height: SdSpacingConstant.h12),
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PremiumUnlockButton(),
        ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: PremiumLockedBody(message: message, icon: icon),
      ),
    );
  }
}

/// A locked chart: [sample] drawn blurred under a scrim, with the unlock button centred on it.
class PremiumChartLock extends ConsumerWidget {
  const PremiumChartLock({required this.sample, super.key});

  static const double blurSigma = 6;
  static const double scrimOpacity = 0.55;

  final Widget sample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Semantics(
      container: true,
      // The sample is excluded below, so nothing says what this card is otherwise.
      label: l10n.premiumLockedCharts,
      child: Stack(
        // Passthrough, not loose: the sample must keep the full-width constraint the chart card gives it, or the chart shrink-wraps.
        fit: StackFit.passthrough,
        children: [
          // - ClipRect: a blur bleeds past its bounds and would fog the card's padding - ExcludeSemantics: VoiceOver must never read the made-up numbers out
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: ExcludeSemantics(child: IgnorePointer(child: sample)),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: context.colorScheme.surface.withValues(
                alpha: scrimOpacity,
              ),
              child: const Center(child: PremiumUnlockButton()),
            ),
          ),
        ],
      ),
    );
  }
}

/// List-tile flavour of [PremiumGate], for Settings rows. Same rule: the locked branch never builds [child], so the action can't be reached.
class PremiumTileGate extends ConsumerWidget {
  const PremiumTileGate({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasPremiumProvider)) return child;

    // The badge is the whole explanation here; the pitch itself is one tap away on the paywall.
    return SettingsTile(
      icon: icon,
      iconColor: context.colorScheme.onSurfaceVariant,
      title: title,
      trailing: const PremiumBadge(),
      onTap: () => NavigationUtils.toPaywall(context, ref),
    );
  }
}

/// Small "Premium" pill used on locked surfaces.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  // The pill is SdTagV2's, not this widget's: the alert row wears the same
  // shape, and two hand-rolled copies of one pill is two chances to drift.
  Widget build(BuildContext context) =>
      SdTagV2(label: context.l10n.premiumBadge);
}
