import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../controllers/blocked_account_controller.dart';

/// Replaces the whole app while the signed-in address carries `blocked: true`.
///
/// A layer in the tree rather than a pushed route (which is how force update
/// does it): the block clears the moment the user signs out, and a plain
/// `if` cannot get out of step with the flag the way a route that has to be
/// popped can. It sits inside `MaterialApp.builder`, so it has the theme and
/// the localizations, and it renders instead of `child` so nothing underneath
/// keeps running.
class BlockedAccountGate extends ConsumerWidget {
  const BlockedAccountGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAccountBlockedProvider)) return child;

    return const BlockedAccountView();
  }
}

/// The blocking screen itself.
///
/// **Its messages are drawn on it, never in a snackbar.** The gate renders
/// instead of the app, navigator included, and `SdSnackBarUtilsV2` draws into
/// that navigator's overlay — so a snackbar raised here went nowhere, and a
/// failed sign-out or email said nothing at all.
class BlockedAccountView extends ConsumerStatefulWidget {
  const BlockedAccountView({super.key});

  @override
  ConsumerState<BlockedAccountView> createState() => _BlockedAccountViewState();
}

class _BlockedAccountViewState extends ConsumerState<BlockedAccountView> {
  /// What the last action could not do, already localized. Null when there is nothing to say.
  String? _message;

  /// Sign-out saves to the account before it signs out, so it is a network round trip.
  bool _signingOut = false;

  Future<void> _signOut() async {
    final AppLocalizations l10n = context.l10n;

    setState(() {
      _signingOut = true;
      _message = null;
    });
    final BlockedSignOut outcome = await ref
        .read(blockedAccountControllerProvider)
        .signOut();

    if (!mounted) return;
    setState(() {
      _signingOut = false;
      _message = switch (outcome) {
        BlockedSignOut.done => null,
        // The same words as the Account screen's refusal: get online, nothing was removed.
        BlockedSignOut.owed => l10n.accountSignOutBlocked,
        BlockedSignOut.failed => l10n.blockedAccountSignOutFailed,
      };
    });
  }

  Future<void> _emailSupport() async {
    final AppLocalizations l10n = context.l10n;

    setState(() => _message = null);
    final bool opened = await ref
        .read(blockedAccountControllerProvider)
        .emailSupport(subject: l10n.contactSupportEmailSubject);

    if (!opened && mounted) {
      setState(() => _message = l10n.contactSupportEmailFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? message = _message;

    return Material(
      color: context.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV2.horizontal,
            vertical: SdSpacingConstant.h24,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SdIconV2(
                  icon: AppIconConstant.locked,
                  size: AppIconSize.xLarge,
                  color: context.colorScheme.primary,
                ),
                SizedBox(height: SdSpacingConstant.h16),
                Text(
                  l10n.blockedAccountTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.titleLarge.w600,
                ),
                SizedBox(height: SdSpacingConstant.h8),
                Text(
                  l10n.blockedAccountBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.bodyMedium.secondary,
                ),
                SizedBox(height: SdSpacingConstant.h24),
                // The way out. Signing out drops the address the row is keyed on, so the app comes back as a fresh session — after this device's records are saved to the account and cleared.
                SdButtonV2(
                  variant: SdButtonVariantV2.primary,
                  label: l10n.blockedAccountSignOut,
                  loading: _signingOut,
                  onPressed: _signOut,
                ),
                SizedBox(height: SdSpacingConstant.h8),
                // The owner blocked the address, so the owner is the only one who can unblock it.
                SdButtonV2(
                  variant: SdButtonVariantV2.secondary,
                  label: l10n.blockedAccountContact,
                  onPressed: _signingOut ? null : _emailSupport,
                ),
                if (message != null) ...<Widget>[
                  SizedBox(height: SdSpacingConstant.h16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.labelSmall.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
