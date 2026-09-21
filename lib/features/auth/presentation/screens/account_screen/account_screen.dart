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
import '../../../../../core/widgets/settings_tile.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../premium/providers.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/enums/auth_error.dart';
import '../../../providers.dart';
import '../../widgets/display_name_dialog.dart';

part 'account_screen_delete_tile.dart';
part 'account_screen_header.dart';
part 'account_screen_premium_section.dart';
part 'account_screen_profile_section.dart';

/// The signed-in user's own record: who they are, what the subscription is, and the way out.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  /// Owned here rather than inside the row that starts it, because what it
  /// switches on covers the whole screen — app bar included. A flag living in
  /// the row could only ever dim the list under it.
  bool _deleting = false;

  /// The same, for the sign-out: it pushes what the device still owes before
  /// wiping the device's copy, so it is a network round trip too.
  bool _signingOut = false;

  bool get _busy => _deleting || _signingOut;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AuthUser? user = switch (ref.watch(authUserProvider)) {
      AsyncData(value: final AuthUser? value) => value,
      _ => null,
    };
    final UserProfile? profile = switch (ref.watch(userProfileProvider)) {
      AsyncData(value: final UserProfile? value) => value,
      _ => null,
    };

    // Deletion is a server call that ends with this route popping itself, so
    // leaving early would land the user on Settings with the work still
    // running and no way back to see how it went.
    return PopScope(
      canPop: !_busy,
      child: Stack(
        children: <Widget>[
          SdScaffoldV2(
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
                  _DeleteAccountTile(
                    deleting: _deleting,
                    onDeletingChanged: (bool deleting) =>
                        setState(() => _deleting = deleting),
                  ),
                  const _DataNote(),
                ],
              ),
              actions: <Widget>[
                _SignOutButton(
                  signingOut: _signingOut,
                  onSigningOutChanged: (bool signingOut) =>
                      setState(() => _signingOut = signingOut),
                ),
              ],
            ),
          ),
          // Over the scaffold, not inside it: the back arrow and Sign Out are
          // exactly the taps that must not land while the account is going.
          if (_busy)
            // A spinner alone would read as a stall here: signing out saves
            // before it wipes, and the wait is the saving.
            _BusyOverlay(
              message: _signingOut ? l10n.accountSignOutSyncing : null,
            ),
        ],
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
            size: AppIconSize.xSmall,
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
  const _SignOutButton({
    required this.signingOut,
    required this.onSigningOutChanged,
  });

  /// The screen's flag, not this button's: it also raises [_BusyOverlay].
  final bool signingOut;
  final ValueChanged<bool> onSigningOutChanged;

  /// The confirm warns, because this device's copy goes with the sign-out.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;

    if (signingOut) return;
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

    if (confirmed != true || !context.mounted) return;

    onSigningOutChanged(true);
    try {
      // False is the device still owing the server, which is the one case where the account keeps this session: wiping now would take records nothing else holds.
      if (!await ref.read(accountControllerProvider).signOut()) {
        if (context.mounted) {
          SdSnackBarUtilsV2.error(context, l10n.accountSignOutBlocked);
        }

        return;
      }
      // This screen assumes an account — without one it goes back to Settings rather than sitting empty.
      if (context.mounted) context.pop();
    } catch (_) {
      // Logged where it happened; the session survives, so retrying is the advice.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.accountSignOutBlocked);
      }
    } finally {
      if (context.mounted) onSigningOutChanged(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdButtonV2(
      variant: SdButtonVariantV2.primary,
      onPressed: signingOut ? null : () => _signOut(context, ref),
      label: signingOut
          ? context.l10n.accountSignOutSyncing
          : context.l10n.settingsSignOut,
      icon: AppIconConstant.signOut,
    );
  }
}
