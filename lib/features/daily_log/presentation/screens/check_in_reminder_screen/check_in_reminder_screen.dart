import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_time_picker_sheet.dart';
import '../../../../../core/widgets/settings_tile.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../providers.dart';
import '../../controllers/check_in_reminder_controller.dart';

/// The evening nudge's own screen: the switch, the time, and what it does.
///
/// A screen rather than one Settings row (owner's call, 2026-09-16). The time
/// lived in that row's subtitle and was edited by tapping the four characters
/// of "20:30" — nothing about a line of text says it can be tapped, so the
/// setting read as fixed. Here the time is a row of its own with its value and
/// a chevron, which is the shape every other editable setting in the app wears.
class CheckInReminderScreen extends ConsumerWidget {
  const CheckInReminderScreen({super.key});

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
    final AppLocalizations l10n = context.l10n;
    final CheckInReminderSettings settings = ref.watch(
      checkInReminderControllerProvider,
    );

    return SdScaffoldV2(
      title: Text(l10n.checkInReminderTile, style: AppTextStyle.titleLarge),
      body: ListView(
        // Full-bleed: both rows are ListTiles, which inset themselves.
        padding: SdContentPaddingV2.fullBleed(context),
        children: <Widget>[
          SettingsTile(
            icon: AppIconConstant.dailyLog,
            title: l10n.checkInReminderSwitch,
            trailing: SdSwitcherV2(
              value: settings.enabled,
              onChanged: (bool value) => _toggle(context, ref, value),
            ),
            // The whole row flips it, not just the switch — the same as every
            // other switch row in the app.
            onTap: () => _toggle(context, ref, !settings.enabled),
          ),
          // Editable with the nudge off too: a time set before it is armed is
          // one less thing to come back for, and the row would otherwise be a
          // dead line most of the time it is read.
          SettingsTile(
            icon: AppIconConstant.reminder,
            title: l10n.checkInReminderTime,
            value: DateTimeUtils.hhmm(settings.hour, settings.minute),
            onTap: () => _pickTime(context, ref),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV2.horizontal,
            ),
            child: Text(
              l10n.checkInReminderTileBody,
              style: AppTextStyle.bodySmall.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
