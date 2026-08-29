import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/auth/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../router/navigation_utils.dart';
import '../../theme/app_icon_constant.dart';
import '../settings_tile.dart';

/// Offers sign-in, or — once there is an account — a way into the account
/// tab, which owns everything else about it (name, email, sign-out).
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);

    if (!signedIn) {
      return SettingsTile(
        icon: AppIconConstant.account,
        title: l10n.settingsAccountSignIn,
        onTap: () => NavigationUtils.toLogin(context),
      );
    }

    // - Signed in: the account lives on its own screen; this row only points there, so sign-out exists in one place.
    // - The email stays off this row — Settings is scrolled past in public, and the account screen is one tap away.
    // - Nothing about sync here: it is a row in "Your data" now (SyncSettingsTile).
    return SettingsTile(
      icon: AppIconConstant.account,
      title: l10n.settingsAccount,
      onTap: () => context.pushNamed(AppRoutes.account.name),
    );
  }
}
