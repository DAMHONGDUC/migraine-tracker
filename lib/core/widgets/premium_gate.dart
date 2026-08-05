import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../core/theme/app_text_style.dart';
import '../../features/premium/providers.dart';
import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import 'settings_tile.dart';

/// Renders [child] for premium users, and a locked pitch otherwise.
///
/// The locked branch never builds [child], so a free user's widget tree
/// simply has no premium data in it — nothing to leak through a blur or an
/// Opacity(0). Gate at the data boundary, not with a visual cover.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    required this.lockedMessage,
    required this.child,
    this.lockedIcon = Icons.lock_outline,
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

class _LockedCard extends ConsumerWidget {
  const _LockedCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SdIconV2(
                  icon: icon,
                  size: SdSpacingConstant.r20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: SdSpacingConstant.w8),
                const PremiumBadge(),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h12),
            Text(message, style: AppTextStyle.bodyMedium),
            SizedBox(height: SdSpacingConstant.h12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SdButtonV2(
                variant: SdButtonVariantV2.secondary,
                onPressed: () => NavigationUtils.toPaywall(context, ref),
                label: l10n.premiumUnlock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List-tile flavour of [PremiumGate], for Settings rows. Same rule: the
/// locked branch never builds [child], so the action can't be reached.
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SdSpacingConstant.w8,
        vertical: SdSpacingConstant.h4,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      ),
      child: Text(
        context.l10n.premiumBadge,
        style: AppTextStyle.labelSmall.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
