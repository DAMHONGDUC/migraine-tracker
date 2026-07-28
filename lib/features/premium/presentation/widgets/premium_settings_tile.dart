import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers.dart';

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
      leading: AppIcon(
        premium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
        color: premium ? context.colorScheme.primary : null,
      ),
      title: Text(l10n.settingsPremium, style: AppTextStyle.bodyLarge),
      subtitle: Text(
        premium ? l10n.accountPremiumActive : l10n.accountPremiumFree,
        style: AppTextStyle.bodyMedium.secondary,
      ),
      // Chevron, never the PremiumBadge: that badge marks a locked teaser,
      // and this row is a way in, not a gate.
      trailing: const AppIcon(Icons.chevron_right),
      onTap: () => context.pushNamed(AppRoutes.premium.name),
    );
  }
}
