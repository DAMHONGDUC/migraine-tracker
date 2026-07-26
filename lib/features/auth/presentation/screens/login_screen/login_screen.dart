import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_spacing_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/enums/auth_error.dart';
import '../../../domain/enums/auth_provider_kind.dart';
import '../../../providers.dart';
import '../../controllers/auth_controller.dart';

part 'login_screen_benefit.dart';
part 'login_screen_buttons.dart';
part 'login_screen_disclosure.dart';
part 'login_screen_pitch.dart';

/// The optional account. Nothing on this screen is required to use the app
/// (hard rule 1) — it exists so a subscription has something durable to hang
/// off, which is why it is what premium gates route through first.
///
/// Pops with `true` once an account exists, so whatever sent the user here
/// (Settings, or a premium gate on its way to the paywall) can continue.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  String _errorMessage(AppLocalizations l10n, AuthError error) =>
      switch (error) {
        AuthError.network => l10n.loginErrorNetwork,
        AuthError.appleUnavailable => l10n.loginErrorApple,
        AuthError.notImplemented => l10n.loginErrorAppleSoon,
        AuthError.accountConflict => l10n.loginErrorConflict,
        AuthError.notConfigured => l10n.loginErrorConfig,
        // Cancelling is not a failure — the controller never surfaces it.
        AuthError.cancelled || AuthError.unknown => l10n.loginErrorGeneric,
      };

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    AuthProviderKind provider,
  ) async {
    final bool signedIn = await ref
        .read(loginControllerProvider.notifier)
        .signIn(provider);

    if (signedIn && context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final LoginState state = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (
      LoginState? previous,
      LoginState next,
    ) {
      final AuthError? error = next.error;
      if (error == null) return;

      AppSnackBarUtils.error(context, _errorMessage(l10n, error));
    });

    return AppScaffold(
      title: Text(l10n.loginTitle, style: AppTextStyle.titleLarge),
      // The pitch sits at the top, the buttons hug the bottom, and the page
      // scrolls once it cannot all fit — long locales and large
      // accessibility text sizes make that a matter of when, not if.
      withScrollView: true,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacingConstant.w24,
          AppScaffold.bodyTopInset(context),
          AppSpacingConstant.w24,
          // AppScaffold's SafeArea already clears the home indicator; this
          // is only the breathing gap above it.
          AppSpacingConstant.h16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const _Pitch(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: AppSpacingConstant.h24),
                _ProviderButtons(
                  state: state,
                  onSignIn: (AuthProviderKind provider) =>
                      _signIn(context, ref, provider),
                ),
                SizedBox(height: AppSpacingConstant.h8),
                AppButton.text(
                  onPressed: state.isBusy ? null : () => context.pop(false),
                  label: l10n.loginNotNow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
