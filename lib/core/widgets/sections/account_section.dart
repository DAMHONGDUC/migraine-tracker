import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../features/auth/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../router/navigation_utils.dart';

/// Offers sign-in, or — once there is an account — a way into the account
/// tab, which owns everything else about it (name, email, sign-out).
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);

    if (!signedIn) {
      return ListTile(
        leading: const SdIconV2(icon: Icons.account_circle_outlined),
        title: Text(l10n.settingsAccountSignIn, style: AppTextStyle.bodyLarge),
        subtitle: Text(
          l10n.settingsAccountSignInSubtitle,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        onTap: () => NavigationUtils.toLogin(context),
      );
    }

    // Signed in, everything about the account lives on its own screen —
    // this row only points there, so sign-out exists in exactly one place.
    // The email stays off this row: Settings is a screen people scroll past
    // in public, and the account screen is one tap away.
    return ListTile(
      leading: const SdIconV2(icon: Icons.account_circle),
      title: Text(l10n.settingsAccount, style: AppTextStyle.bodyLarge),
      subtitle: Text(
        l10n.settingsAccountSignedInSubtitle,
        style: AppTextStyle.bodyMedium.secondary,
      ),
      trailing: const SdIconV2(icon: Icons.chevron_right),
      onTap: () => context.pushNamed(AppRoutes.account.name),
    );
  }
}
