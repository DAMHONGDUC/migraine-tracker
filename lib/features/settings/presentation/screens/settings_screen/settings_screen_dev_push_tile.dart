part of 'settings_screen.dart';

/// Dev-only: asks the Firebase backend to push a notification to this device
/// — FCM to APNs to here, the whole path a real alert takes.
///
/// The pair to [_DevLocalNotificationTile]; its title and its snackbars say
/// "Firebase" so the arriving notification identifies its own sender.
///
/// The only way to prove the APNs key, the entitlement and the token line up,
/// because none of that exists on a Simulator and no test can stand in for
/// it. The callable only ever targets the caller's own registered device.
class _DevPushTile extends ConsumerStatefulWidget {
  const _DevPushTile();

  @override
  ConsumerState<_DevPushTile> createState() => _DevPushTileState();
}

class _DevPushTileState extends ConsumerState<_DevPushTile> {
  bool _sending = false;

  Future<void> _send() async {
    final AppLocalizations l10n = context.l10n;

    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(alertRegistrationRepositoryProvider).sendTestPush();

      if (mounted) SdSnackBarUtilsV2.success(context, l10n.settingsDevPushSent);
    } catch (error, stackTrace) {
      // The reason is the whole point of the row — the console keeps the
      // stack trace the snackbar has no room for.
      SdLogger.error(
        LogTagConstant.devPush,
        'Test push failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        SdSnackBarUtilsV2.error(context, l10n.settingsDevPushFailed('$error'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: AppIconConstant.reminderActive,
      iconColor: context.colorScheme.primary,
      title: context.l10n.settingsDevPush,
      trailing: _sending
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _send,
    );
  }
}
