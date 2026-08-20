part of 'settings_screen.dart';

/// Dev-only: schedules a local notification ~10s out **from the device
/// itself**, so a developer can confirm delivery without waiting for a real
/// reminder — and without the backend being involved at all.
///
/// The pair to [_DevPushTile], which is the same test through Firebase. The
/// two rows and every string they show name their sender, because "test
/// notification" and "test push" read as the same row and a developer holding
/// a phone cannot tell which one just arrived. Deliberately not gated on an
/// account:
/// nothing about a local notification needs one — the OS schedules it on the
/// device. That is also the difference the two rows exist to tell apart. When
/// the reminder never arrives, this one says whether the fault is on the
/// device or in the backend that sends the push.
///
/// It lived in the medications tab's app bar behind `kDebugMode`, which put a
/// developer tool in the chrome of a screen users see, next to Search and Add.
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
      // Asked for here rather than assumed: the tool is most useful on a
      // device that has never been asked, which is the state it is testing.
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
      // The reason is the whole point of the row — the console keeps the
      // stack trace the snackbar has no room for.
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
      icon: Icons.notification_add_outlined,
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
