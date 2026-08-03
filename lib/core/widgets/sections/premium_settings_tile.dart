import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/premium/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../settings_tile.dart';

/// Settings row for the subscription: says where it stands and opens
/// `PremiumScreen` for the rest. Shown only to signed-in users — the
/// Settings section decides that, so this stays a plain row.
class PremiumSettingsTile extends ConsumerWidget {
  const PremiumSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return SettingsTile(
      icon: premium
          ? Icons.workspace_premium
          : Icons.workspace_premium_outlined,
      iconColor: premium ? context.colorScheme.primary : null,
      title: l10n.settingsPremium,
      // The state is the row's value, so it reads at the end like every other
      // one — and it is a chevron, never the PremiumBadge: that badge marks a
      // locked teaser, and this row is a way in, not a gate.
      value: premium ? l10n.accountPremiumActive : l10n.accountPremiumFree,
      onTap: () => context.pushNamed(AppRoutes.premium.name),
    );
  }
}
