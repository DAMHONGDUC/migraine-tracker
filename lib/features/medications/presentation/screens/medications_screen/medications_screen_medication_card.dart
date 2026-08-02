part of 'medications_screen.dart';

class _MedicationCard extends ConsumerStatefulWidget {
  const _MedicationCard({
    required this.medication,
    this.highlighted = false,
    super.key,
  });

  final Medication medication;

  /// Briefly flashed (a primary border + glow) when the user jumped here from
  /// the dashboard's next-reminder banner.
  final bool highlighted;

  /// Reminders beyond this many start collapsed — a med taken 4+ times a
  /// day is rare, and the "Add reminder" action should stay reachable
  /// without scrolling through every row first.
  static const collapsedLimit = 3;

  @override
  ConsumerState<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<_MedicationCard> {
  bool _expanded = false;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await MedicationNameDialog(
      initial: widget.medication.name,
    ).show(context);
    if (name == null) return;
    await ref
        .read(medicationsControllerProvider)
        .rename(widget.medication, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSdDialogV2<bool>(
      context,
      builder: (dialogContext) => SdDialogV2(
        title: l10n.medicationsDeleteTitle,
        content: Text(
          l10n.medicationsDeleteBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(medicationsControllerProvider).delete(widget.medication.id);
  }

  void _openActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    showSdBottomSheetV2<void>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const SdIconV2(icon: Icons.alarm_add),
              title: Text(l10n.remindersAdd, style: AppTextStyle.bodyLarge),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addReminder(context, ref);
              },
            ),
            ListTile(
              leading: const SdIconV2(icon: Icons.edit_outlined),
              title: Text(
                l10n.medicationsEditAction,
                style: AppTextStyle.bodyLarge,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _rename(context, ref);
              },
            ),
            ListTile(
              leading: SdIconV2(icon: Icons.delete_outline, color: scheme.error),
              title: Text(
                l10n.settingsDeleteConfirmAction,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _delete(context, ref);
              },
            ),
            SizedBox(height: SdSpacingV2.h8),
          ],
        ),
      ),
    );
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    // A reminder is useless without notification permission — ask up front and,
    // if it's permanently off, AppPermission shows the Settings sheet for us.
    final granted = await ref
        .read(appPermissionProvider)
        .ensure(context, AppPermissionType.notification);
    if (!granted || !context.mounted) return;

    // Default a few minutes ahead so the reminder actually fires soon —
    // defaulting to "now" would land in the past and roll to tomorrow.
    final base = DateTime.now().add(const Duration(minutes: 5));
    final time = await AppTimePickerSheet(
      title: l10n.remindersAdd,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    ).show(context);
    if (time == null || !context.mounted) return;

    final minuteOfDay = time.hour * 60 + time.minute;
    await ref
        .read(remindersControllerProvider)
        .add(
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          minuteOfDay: minuteOfDay,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    if (!context.mounted) return;
    _ReminderSnack.show(context, minuteOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reminders = ref.watch(
      remindersForMedicationProvider(widget.medication.id),
    );
    final createdAt = widget.medication.createdAt;
    final addedLabel = createdAt == null
        ? l10n.medicationsAddedUnknown
        : l10n.medicationsAddedOn(
            DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal()),
          );

    final overflowing = reminders.length > _MedicationCard.collapsedLimit;
    final visibleReminders = overflowing && !_expanded
        ? reminders.take(_MedicationCard.collapsedLimit).toList()
        : reminders;

    final rowPadding = EdgeInsets.symmetric(
      horizontal: SdContentPaddingV2.horizontal,
    ).copyWith(right: SdContentPaddingV2.horizontal / 2);

    // Drive the highlight from a single 0..1 value and derive the border +
    // glow from it — building the decoration per-frame keeps the fade
    // monotonic. (AnimatedContainer lerps the whole BoxDecoration, and
    // interpolating boxShadow toward null flickers brighter near the end.)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.highlighted ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) => Container(
        // Glow sits behind the card; the border is painted in the FOREGROUND
        // so it isn't hidden under the card's opaque surface.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SdSpacingV2.r12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35 * t),
              blurRadius: SdSpacingV2.r16 * t,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SdSpacingV2.r12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: t),
            width: 2,
          ),
        ),
        child: child,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: rowPadding,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const SdIconV2(icon: Icons.medication_outlined),
                title: Text(
                  widget.medication.name,
                  style: AppTextStyle.titleMedium,
                ),
                subtitle: Text(
                  addedLabel,
                  style: AppTextStyle.bodySmall.secondary,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SdIconButtonV2(
                      onPressed: () => _addReminder(context, ref),
                      icon: const SdIconV2(icon: Icons.add_alarm),
                    ),
                    SizedBox(width: SdSpacingV2.w2),
                    SdIconButtonV2(
                      icon: const SdIconV2(icon: Icons.more_vert),
                      onPressed: () => _openActions(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            for (final view in visibleReminders) _ReminderRow(view: view),
            if (overflowing)
              _ExpandRemindersToggle(
                expanded: _expanded,
                hiddenCount: reminders.length - _MedicationCard.collapsedLimit,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
          ],
        ),
      ),
    );
  }
}
