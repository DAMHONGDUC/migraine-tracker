part of 'settings_screen.dart';

/// Dev-only: schedules a local notification ~10s out from the device itself, so a developer can confirm delivery without waiting for a real reminder.
class _DevLocalNotificationTile extends ConsumerStatefulWidget {
  const _DevLocalNotificationTile();

  @override
  ConsumerState<_DevLocalNotificationTile> createState() =>
      _DevLocalNotificationTileState();
}

class _DevLocalNotificationTileState
    extends ConsumerState<_DevLocalNotificationTile> {
  bool _sending = false;

  Future<void> _send() async {
    final AppLocalizations l10n = context.l10n;

    if (_sending) return;
    setState(() => _sending = true);
    try {
      // Asked for here rather than assumed: the tool is most useful on a device that has never been asked, which is the state it is testing.
      final bool granted = await ref
          .read(appPermissionProvider)
          .ensure(context, AppPermissionType.notification);

      if (!granted || !mounted) return;

      await ref
          .read(remindersControllerProvider)
          .sendTest(
            title: l10n.remindersTestTitle,
            body: l10n.remindersTestBody,
          );

      if (mounted) SdSnackBarUtilsV2.info(context, l10n.remindersTestScheduled);
    } catch (error, stackTrace) {
      // The reason is the whole point of the row — the console keeps the stack trace the snackbar has no room for.
      SdLogger.error(
        LogTagConstant.reminders,
        'Test local notification failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        SdSnackBarUtilsV2.error(
          context,
          l10n.settingsDevLocalNotificationFailed('$error'),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: AppIconConstant.notificationAdd,
      iconColor: context.colorScheme.primary,
      title: context.l10n.settingsDevLocalNotification,
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
