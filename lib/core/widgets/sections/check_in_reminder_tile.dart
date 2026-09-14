import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/daily_log/presentation/controllers/check_in_reminder_controller.dart';
import '../../../features/daily_log/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_icon_constant.dart';
import '../../theme/app_icon_size.dart';
import '../../theme/app_text_style.dart';
import '../../utils/date_time_utils.dart';
import '../app_time_picker_sheet.dart';

/// Settings switch for the evening check-in nudge, with its time on the same row.
///
/// One row rather than a switch above a time row, for the reason the alert
/// controls are one row: two titles saying the same word, with the number the
/// thing actually runs on readable only by opening the second.
class CheckInReminderTile extends ConsumerWidget {
  const CheckInReminderTile({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final bool on = await ref
        .read(checkInReminderControllerProvider.notifier)
        .setEnabled(value);

    // Refused by the OS: the app's switch is off, and the user needs to know where the refusal came from.
    if (value && !on && context.mounted) {
      SdSnackBarUtilsV2.error(context, context.l10n.checkInReminderDenied);
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final CheckInReminderSettings settings = ref.read(
      checkInReminderControllerProvider,
    );
    final TimeOfDay? picked = await AppTimePickerSheet(
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    ).show(context);

    if (picked == null) return;
    await ref
        .read(checkInReminderControllerProvider.notifier)
        .setTime(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckInReminderSettings settings = ref.watch(
      checkInReminderControllerProvider,
    );

    return SwitchListTile(
      secondary: SdIconV2(
        icon: AppIconConstant.dailyLog,
        size: AppIconSize.medium,
      ),
      title: Text(
        context.l10n.checkInReminderTile,
        style: AppTextStyle.bodyLarge,
      ),
      // The time is the setting; the body says what the switch does while it is off.
      subtitle: settings.enabled
          ? GestureDetector(
              onTap: () => _pickTime(context, ref),
              child: Text(
                DateTimeUtils.hhmm(settings.hour, settings.minute),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            )
          : Text(
              context.l10n.checkInReminderTileBody,
              style: AppTextStyle.bodySmall.secondary,
            ),
      value: settings.enabled,
      onChanged: (bool value) => _toggle(context, ref, value),
    );
  }
}
