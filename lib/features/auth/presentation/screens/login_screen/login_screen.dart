import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/enums/auth_error.dart';
import '../../../domain/enums/auth_provider_kind.dart';
import '../../../providers.dart';
import '../../controllers/auth_controller.dart';

part 'login_screen_buttons.dart';
part 'login_screen_disclosure.dart';
part 'login_screen_pitch.dart';

/// The optional account (hard rule 1) — it exists so a subscription has
/// something durable to hang off. Pops `true` once an account exists, so
/// whatever sent the user here can continue.
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

      SdSnackBarUtilsV2.error(context, _errorMessage(l10n, error));
    });

    return SdScaffoldV2(
      title: Text(l10n.loginTitle, style: AppTextStyle.titleLarge),
      // Scrolls: long locales and large text sizes can make the pitch overflow.
      body: SdActionViewV2(
        content: const _Pitch(),
        actions: <Widget>[
          _ProviderButtons(
            state: state,
            onSignIn: (AuthProviderKind provider) =>
                _signIn(context, ref, provider),
          ),
          // Text, not a button: the two provider buttons above are the offer,
          // and a third button under them reads as a third way in.
          SdTextActionV2(
            label: l10n.loginNotNow,
            onTap: state.isBusy ? null : () => context.pop(false),
          ),
        ],
      ),
    );
  }
}
