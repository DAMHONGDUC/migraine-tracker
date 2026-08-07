part of 'notifications_screen.dart';

/// One row. The two kinds go to different places on tap — a reminder opens
/// the medication it was about, an alert opens a sheet explaining it — which
/// is the whole reason `kind` is stored rather than inferred.
class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  /// Nothing is stored but the facts, so the line is built here from the
  /// medication's current name — rename it and the history renames with it.
  String _title(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return switch (notification.kind) {
      NotificationKind.pressureAlert => l10n.notificationPressureTitle,
      NotificationKind.medicationReminder =>
        _medicationName(ref) == null
            ? l10n.notificationReminderUnknown
            : l10n.notificationReminderTitle(_medicationName(ref)!),
    };
  }

  String? _medicationName(WidgetRef ref) {
    final String? id = notification.medicationId;

    if (id == null) return null;
    return ref.watch(medicationByIdProvider(id))?.name;
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    switch (notification.kind) {
      case NotificationKind.pressureAlert:
        await PressureAlertSheet(notification: notification).show(context);
      case NotificationKind.medicationReminder:
        final String? id = notification.medicationId;

        // Deleted since: the detail screen says so itself rather than this
        // row guessing at what to do instead.
        if (id == null) return;
        await context.pushNamed<void>(
          AppRoutes.medication.name,
          pathParameters: <String, String>{AppRoutes.medicationIdParam: id},
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isAlert = notification.kind == NotificationKind.pressureAlert;
    final DateTime at = notification.occurredAt.toLocal();

    return SdCardV2(
      onTap: () => _open(context, ref),
      child: ListTile(
        leading: SdIconBadgeV2(
          icon: isAlert ? Icons.trending_down : Icons.alarm,
          color: isAlert
              ? context.colorScheme.secondary
              : context.colorScheme.primary,
        ),
        title: Text(_title(context, ref), style: AppTextStyle.bodyLarge),
        subtitle: Text(
          DateFormat.yMMMd(l10n.localeName).add_Hm().format(at),
          style: AppTextStyle.bodyMedium.secondary,
        ),
        // Unread is told by weight as well as the dot on the dashboard —
        // colour alone would be the only signal otherwise.
        trailing: SdBadgeDotV2(
          showing: !notification.isRead,
          child: SdIconV2(
            icon: Icons.chevron_right,
            size: SdSpacingConstant.r24,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
