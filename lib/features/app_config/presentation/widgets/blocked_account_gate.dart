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
class BlockedAccountView extends ConsumerWidget {
  const BlockedAccountView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

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
                const _SignOutButton(),
                SizedBox(height: SdSpacingConstant.h8),
                const _ContactButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The way out. Signing out drops the address the row is keyed on, so the app comes back — with every log still on the device.
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdButtonV2(
      variant: SdButtonVariantV2.primary,
      label: context.l10n.blockedAccountSignOut,
      onPressed: () async {
        final AppLocalizations l10n = context.l10n;
        final bool signedOut = await ref
            .read(blockedAccountControllerProvider)
            .signOut();

        if (!signedOut && context.mounted) {
          SdSnackBarUtilsV2.error(context, l10n.blockedAccountSignOutFailed);
        }
      },
    );
  }
}

/// The owner blocked the address, so the owner is the only one who can unblock it.
class _ContactButton extends ConsumerWidget {
  const _ContactButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdButtonV2(
      variant: SdButtonVariantV2.secondary,
      label: context.l10n.blockedAccountContact,
      onPressed: () async {
        final AppLocalizations l10n = context.l10n;
        final bool opened = await ref
            .read(blockedAccountControllerProvider)
            .emailSupport(subject: l10n.contactSupportEmailSubject);

        if (!opened && context.mounted) {
          SdSnackBarUtilsV2.error(context, l10n.contactSupportEmailFailed);
        }
      },
    );
  }
}
