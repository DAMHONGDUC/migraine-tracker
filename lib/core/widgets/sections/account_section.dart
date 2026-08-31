import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/auth/providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../router/navigation_utils.dart';
import '../../theme/app_icon_constant.dart';
import '../settings_tile.dart';

/// Offers sign-in, or — once there is an account — a way into the account tab,
/// which owns everything else about it (name, email, sign-out).
///
/// **The row says which of the two it is without being opened** (owner's
/// call). It used to read "Sign in" or "Account" and nothing else, so the one
/// state a user checks Settings for was two taps away, and "Account" on an
/// anonymous session looked like an account.
///
/// **The state, never the address** (owner's call, reversing a version that
/// showed the email). Settings is read in public; an address printed on a row
/// anyone glancing over can see is a cost the row's answer does not need —
/// "signed in" is the whole question, and the account screen behind it is
/// where the address belongs.
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
        // The same muted tag the alerts row wears when it is off: a state that is not on has no colour to earn.
        valueTag: SdTagV2(
          label: l10n.settingsAccountSignedOut,
          color: context.colorScheme.onSurfaceVariant,
        ),
        onTap: () => NavigationUtils.toLogin(context),
      );
    }

    // - Signed in: the account lives on its own screen; this row only points there, so sign-out exists in one place.
    return SettingsTile(
      icon: AppIconConstant.account,
      title: l10n.settingsAccount,
      // The accent, against the off state's grey: the two tags are the same shape, so colour is what tells them apart at a glance.
      valueTag: SdTagV2(label: l10n.settingsAccountSignedIn),
      onTap: () => context.pushNamed(AppRoutes.account.name),
    );
  }
}
