import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/premium/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_icon_constant.dart';
import '../premium_gate.dart';
import '../settings_tile.dart';

/// Settings row for the subscription: says where it stands and opens `SubscriptionScreen` for the rest.
class PremiumSettingsTile extends ConsumerWidget {
  const PremiumSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return SettingsTile(
      icon: AppIconConstant.premium,
      // One glyph, tinted when it is on. The tag beside it says the same thing in words, so the colour is the second signal, never the only one.
      iconColor: premium ? context.colorScheme.primary : null,
      title: l10n.settingsPremium,
      // One word, as a tag, like the account row above it: "Premium is active" was a sentence where the row only had to name a state.
      // PremiumBadge itself when it is on — the row and every other premium marker in the app are then literally the same widget.
      valueTag: premium
          ? const PremiumBadge()
          : SdTagV2(
              label: l10n.premiumPlanFree,
              color: context.colorScheme.onSurfaceVariant,
            ),
      onTap: () => context.pushNamed(AppRoutes.premium.name),
    );
  }
}
