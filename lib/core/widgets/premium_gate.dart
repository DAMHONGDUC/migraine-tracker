import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/premium/providers.dart';
import '../extensions/context_extensions.dart';
import '../router/navigation_utils.dart';
import 'settings_tile.dart';

/// Renders [child] once unlocked, and a locked Settings row otherwise. The locked branch never builds [child], so the action can't be reached.
class PremiumTileGate extends ConsumerWidget {
  const PremiumTileGate({
    required this.icon,
    required this.title,
    required this.child,
    this.access,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// What opens the gate; premium when null. Alerts pass their own, which the owner can open to everyone.
  final Provider<bool>? access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(access ?? hasPremiumProvider)) return child;

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
