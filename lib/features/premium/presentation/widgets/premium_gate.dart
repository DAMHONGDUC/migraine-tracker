import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../providers.dart';

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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  icon,
                  size: AppSpacingConstant.r20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: AppSpacingConstant.w8),
                const PremiumBadge(),
              ],
            ),
            SizedBox(height: AppSpacingConstant.h12),
            Text(message, style: AppTextStyle.bodyMedium),
            SizedBox(height: AppSpacingConstant.h12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppButton.secondary(
                onPressed: () => NavigationUtils.unlockPremium(context, ref),
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
    required this.lockedMessage,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final String lockedMessage;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasPremiumProvider)) return child;
    return ListTile(
      leading: AppIcon(icon, color: context.colorScheme.onSurfaceVariant),
      title: Text(title, style: AppTextStyle.bodyLarge),
      subtitle: Text(lockedMessage, style: AppTextStyle.bodyMedium.secondary),
      trailing: const PremiumBadge(),
      onTap: () => NavigationUtils.unlockPremium(context, ref),
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
        horizontal: AppSpacingConstant.w8,
        vertical: AppSpacingConstant.h4,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
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
