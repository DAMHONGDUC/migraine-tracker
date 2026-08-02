import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../features/premium/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';

/// Settings row for the subscription: says where it stands and opens
/// `PremiumScreen` for the rest. Shown only to signed-in users — the
/// Settings section decides that, so this stays a plain row.
class PremiumSettingsTile extends ConsumerWidget {
  const PremiumSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool premium = ref.watch(hasPremiumProvider);

    return ListTile(
      leading: SdIconV2(
        icon: premium
            ? Icons.workspace_premium
            : Icons.workspace_premium_outlined,
        color: premium ? context.colorScheme.primary : null,
      ),
      title: Text(l10n.settingsPremium, style: AppTextStyle.bodyLarge),
      subtitle: Text(
        premium ? l10n.accountPremiumActive : l10n.accountPremiumFree,
        style: AppTextStyle.bodyMedium.secondary,
      ),
      // Chevron, never the PremiumBadge: that badge marks a locked teaser,
      // and this row is a way in, not a gate.
      trailing: const SdIconV2(icon: Icons.chevron_right),
      onTap: () => context.pushNamed(AppRoutes.premium.name),
    );
  }
}
