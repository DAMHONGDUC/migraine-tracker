part of 'settings_screen.dart';

/// Dev-only: throw every trace of use away and land back on onboarding, the
/// way a first install does. Sits next to the seed tile, behind the same
/// `!AppEnv.isProd` guard on the whole section.
///
/// It confirms first even though nobody real can reach it — this one is
/// destructive AND kicks you off the screen, so a mis-tap next to "seed"
/// would be an unpleasant surprise mid-testing.
class _DevResetTile extends ConsumerStatefulWidget {
  const _DevResetTile();

  @override
  ConsumerState<_DevResetTile> createState() => _DevResetTileState();
}

class _DevResetTileState extends ConsumerState<_DevResetTile> {
  bool _running = false;

  Future<void> _reset() async {
    final AppLocalizations l10n = context.l10n;

    if (_running) return;

    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.settingsDevResetConfirmTitle,
        content: Text(
          l10n.settingsDevResetConfirmBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDevResetConfirmAction,
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _running = true);
    try {
      await ref.read(settingsControllerProvider).resetToOnboarding();

      // The router only redirects to onboarding on a route change — send the user there directly.
      if (mounted) context.goNamed(AppRoutes.onboarding.name);
    } catch (_) {
      if (mounted) {
        SdSnackBarUtilsV2.error(context, l10n.settingsDevResetFailed);
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SettingsTile(
      icon: Icons.restart_alt,
      titleColor: context.colorScheme.error,
      title: l10n.settingsDevReset,
      trailing: _running
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _reset,
    );
  }
}
