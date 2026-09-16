import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/daily_log/presentation/controllers/check_in_reminder_controller.dart';
import '../../../features/daily_log/providers.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_router.dart';
import '../../theme/app_icon_constant.dart';
import '../../utils/date_time_utils.dart';
import '../settings_tile.dart';

/// Settings row for the evening check-in nudge — a door, with its state on it.
///
/// It used to be the whole control: a switch, and the time as four tappable
/// characters in the subtitle. Nothing about a line of text says it can be
/// tapped, so the time read as fixed; it has a screen of its own now
/// (`CheckInReminderScreen`), and this row does what the alerts row does —
/// says where the setting stands and opens the place it is changed.
class CheckInReminderTile extends ConsumerWidget {
  const CheckInReminderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckInReminderSettings settings = ref.watch(
      checkInReminderControllerProvider,
    );

    return SettingsTile(
      icon: AppIconConstant.dailyLog,
      title: context.l10n.checkInReminderTile,
      // The time IS the setting once it is on, so that is what the row shows;
      // off, the word is the whole state and a time nothing fires at would
      // read as one that does.
      value: settings.enabled
          ? DateTimeUtils.hhmm(settings.hour, settings.minute)
          : context.l10n.alertsStatusOff,
      onTap: () => context.pushNamed(AppRoutes.checkInReminder.name),
    );
  }
}
