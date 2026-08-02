import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_spacing_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_action_view.dart';
import '../../../../../core/widgets/buttons/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_section_header.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../premium/providers.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../providers.dart';
import '../../widgets/display_name_dialog.dart';

part 'account_screen_header.dart';
part 'account_screen_premium_section.dart';
part 'account_screen_profile_section.dart';

/// The signed-in user's own record: who they are, what the subscription is,
/// and the way out. Pushed from the Settings account row; the router's
/// redirect turns it away while signed out, so it can assume an account.
///
/// Health data is deliberately absent: attacks live on the device and in
/// their own encrypted subcollection, never in the account document
/// (hard rule 1). [_DataNote] says so on the screen, not just in a comment.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AuthUser? user = switch (ref.watch(authUserProvider)) {
      AsyncData(value: final AuthUser? value) => value,
      _ => null,
    };
    final UserProfile? profile = switch (ref.watch(userProfileProvider)) {
      AsyncData(value: final UserProfile? value) => value,
      _ => null,
    };

    return AppScaffold(
      title: Text(l10n.accountTitle, style: AppTextStyle.titleLarge),
      body: AppActionView(
        // Full-bleed: every row here is a ListTile, which insets itself.
        contentPadding: EdgeInsets.zero,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AccountHeader(user: user, profile: profile),
            AppSectionHeader(l10n.accountSectionProfile),
            _ProfileSection(user: user, profile: profile),
            AppSectionHeader(l10n.accountSectionSubscription),
            const _PremiumSection(),
            const _DataNote(),
          ],
        ),
        actions: const <Widget>[_SignOutButton()],
      ),
    );
  }
}

/// What the account document holds, in the user's words. Sign-in already
/// discloses the sync; this is the same promise where they can re-read it.
class _DataNote extends StatelessWidget {
  const _DataNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacingConstant.w16,
        AppSpacingConstant.h24,
        AppSpacingConstant.w16,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIcon(
            icon: Icons.lock_outline,
            size: AppSpacingConstant.r16,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacingConstant.w8),
          Expanded(
            child: Text(
              context.l10n.accountDataNote,
              style: AppTextStyle.bodySmall.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  /// The confirm is there to say nothing is lost, not to warn.
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
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton(
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsSignOut,
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(accountControllerProvider).signOut();
    // This screen assumes an account — without one there is nothing left on
    // it, so it goes back to Settings rather than sitting there empty.
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      variant: AppButtonVariant.outlined,
      onPressed: () => _signOut(context, ref),
      label: context.l10n.settingsSignOut,
      icon: Icons.logout,
    );
  }
}
