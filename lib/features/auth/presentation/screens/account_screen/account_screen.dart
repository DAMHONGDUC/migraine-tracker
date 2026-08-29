import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../premium/providers.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums/auth_error.dart';
import '../../../providers.dart';
import '../../widgets/display_name_dialog.dart';

part 'account_screen_delete_button.dart';
part 'account_screen_header.dart';
part 'account_screen_premium_section.dart';
part 'account_screen_profile_section.dart';

/// The signed-in user's own record: who they are, what the subscription is, and the way out.
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

    return SdScaffoldV2(
      title: Text(l10n.accountTitle, style: AppTextStyle.titleLarge),
      body: SdActionViewV2(
        // Full-bleed: every row here is a ListTile, which insets itself.
        contentPadding: EdgeInsets.zero,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AccountHeader(user: user, profile: profile),
            SdSectionHeaderV2(l10n.accountSectionProfile),
            _ProfileSection(user: user, profile: profile),
            SdSectionHeaderV2(l10n.accountSectionSubscription),
            const _PremiumSection(),
            const _DataNote(),
          ],
        ),
        actions: const <Widget>[_SignOutButton(), _DeleteAccountButton()],
      ),
    );
  }
}

/// What the account document holds, in the user's words. Sign-in already discloses the sync; this is the same promise where they can re-read it.
class _DataNote extends StatelessWidget {
  const _DataNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdSpacingConstant.w16,
        SdSpacingConstant.h24,
        SdSpacingConstant.w16,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SdIconV2(
            icon: AppIconConstant.locked,
            size: AppIconSize.inline,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: SdSpacingConstant.w8),
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
    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.settingsSignOutConfirmTitle,
        content: Text(
          l10n.settingsSignOutConfirmBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsSignOut,
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(accountControllerProvider).signOut();
    // This screen assumes an account — without one it goes back to Settings rather than sitting empty.
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdButtonV2(
      variant: SdButtonVariantV2.primary,
      onPressed: () => _signOut(context, ref),
      label: context.l10n.settingsSignOut,
      icon: AppIconConstant.signOut,
    );
  }
}
