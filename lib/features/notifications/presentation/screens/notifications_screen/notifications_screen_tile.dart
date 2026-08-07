part of 'notifications_screen.dart';

/// One row: what it was and when. Tapping opens the detail screen, which
/// is where the type decides what the user is offered.
class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  /// Nothing is stored but the facts, so the line is built here from the
  /// medication's current name — rename it and the history renames with it.
  String _title(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return switch (notification.type) {
      NotificationType.pressureAlert => l10n.notificationPressureTitle,
      NotificationType.medicationReminder =>
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

  /// One destination for every row, whatever the type. What the type decides
  /// is what the detail screen offers, not whether the user gets one.
  void _open(BuildContext context) => context.pushNamed<void>(
    AppRoutes.notification.name,
    pathParameters: <String, String>{
      AppRoutes.notificationIdParam: notification.id,
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isAlert = notification.type == NotificationType.pressureAlert;
    final DateTime at = notification.occurredAt.toLocal();

    return SdCardV2(
      onTap: () => _open(context),
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
        // A dot, not a count: per row there is only ever one of it, so a
        // number would say nothing the dot does not.
        trailing: SdBadgeV2(
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
