import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/auth_user.dart';
import '../../providers.dart';

/// The account row in Settings: one tile that either offers sign-in or shows
/// who is signed in, with sign-out behind a confirm.
///
/// Signing out is not destructive — hard rule 1 means everything except the
/// subscription keeps working — so the confirm exists to say exactly that,
/// not to warn about data loss.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showAppDialog<bool>(
      context,
      builder: (BuildContext dialogContext) => AppDialog(
        title: l10n.settingsSignOutConfirmTitle,
        content: Text(
          l10n.settingsSignOutConfirmBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: <Widget>[
          AppButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsSignOut,
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(accountControllerProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);

    if (!signedIn) {
      return ListTile(
        leading: const AppIcon(Icons.account_circle_outlined),
        title: Text(l10n.settingsAccountSignIn, style: AppTextStyle.bodyLarge),
        subtitle: Text(
          l10n.settingsAccountSignInSubtitle,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        onTap: () => NavigationUtils.toLogin(context),
      );
    }

    final AuthUser? user = ref.watch(authUserProvider).value;

    return ListTile(
      leading: const AppIcon(Icons.account_circle),
      title: Text(
        user?.label ?? l10n.settingsAccountSignedIn,
        style: AppTextStyle.bodyLarge,
      ),
      subtitle: Text(
        l10n.settingsAccountSignedInSubtitle,
        style: AppTextStyle.bodyMedium.secondary,
      ),
      trailing: AppButton.text(
        onPressed: () => _signOut(context, ref),
        label: l10n.settingsSignOut,
        compact: true,
      ),
    );
  }
}
