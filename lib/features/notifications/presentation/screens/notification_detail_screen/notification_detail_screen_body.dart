part of 'notification_detail_screen.dart';

/// The reading, then the action. `SdActionViewV2` so the button holds the
/// bottom edge and the content above it can grow.
class _Body extends ConsumerWidget {
  const _Body({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool isAlert = notification.type == NotificationType.pressureAlert;
    final Medication? medication = _medication(ref);
    final DateTime at = notification.occurredAt.toLocal();

    return SdActionViewV2(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdIconBadgeV2(
            icon: isAlert ? AppIconConstant.trendDown : AppIconConstant.reminder,
            color: isAlert
                ? context.colorScheme.secondary
                : context.colorScheme.primary,
            size: AppIconSize.display,
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          Text(
            _headline(l10n, medication),
            style: AppTextStyle.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            DateFormat.yMMMMd(l10n.localeName).add_Hm().format(at),
            style: AppTextStyle.bodyMedium.secondary,
            textAlign: TextAlign.center,
          ),
          if (_body(l10n) case final String body) ...<Widget>[
            SizedBox(height: SdContentPaddingV2.sectionGap),
            Text(
              body,
              style: AppTextStyle.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: <Widget>[
        _action(context, ref, isAlert: isAlert, medication: medication),
      ],
    );
  }

  Medication? _medication(WidgetRef ref) {
    final String? id = notification.medicationId;

    if (id == null) return null;
    return ref.watch(medicationByIdProvider(id));
  }

  /// Built from the medication's current name, never a stored string — rename
  /// it and the history renames with it.
  String _headline(AppLocalizations l10n, Medication? medication) =>
      switch (notification.type) {
        NotificationType.pressureAlert => l10n.notificationPressureTitle,
        NotificationType.medicationReminder =>
          medication == null
              ? l10n.notificationReminderUnknown
              : l10n.notificationReminderTitle(medication.name),
      };

  /// Null where there is nothing more to say than the headline — a reminder
  /// is its own explanation.
  String? _body(AppLocalizations l10n) {
    final double? drop = notification.pressureDropHpa;

    if (notification.type != NotificationType.pressureAlert) return null;
    // A drop the payload never carried leaves the reading out rather than
    // printing a number the forecast did not give.
    if (drop == null) return null;
    return l10n.notificationPressureBody(
      NumberFormat.decimalPattern(l10n.localeName).format(drop.abs()),
    );
  }

  /// One button, and which one is the whole reason the type is stored.
  ///
  /// A reminder whose medication has since been deleted gets the disabled
  /// button rather than none: the row still says what it was, and a button
  /// that vanishes reads as a bug.
  Widget _action(
    BuildContext context,
    WidgetRef ref, {
    required bool isAlert,
    required Medication? medication,
  }) {
    final AppLocalizations l10n = context.l10n;

    if (isAlert) {
      return SdButtonV2(
        variant: SdButtonVariantV2.secondary,
        icon: AppIconConstant.lineChart,
        onPressed: () => NavigationUtils.toPressure(context, ref),
        label: l10n.notificationPressureAction,
      );
    }
    return SdButtonV2(
      variant: SdButtonVariantV2.primary,
      icon: AppIconConstant.medication,
      onPressed: medication == null
          ? null
          : () => context.pushNamed<void>(
              AppRoutes.medication.name,
              pathParameters: <String, String>{
                AppRoutes.medicationIdParam: medication.id,
              },
            ),
      label: l10n.notificationMedicationAction,
    );
  }
}
