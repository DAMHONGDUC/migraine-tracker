import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../medications/domain/entities/next_reminder.dart';
import 'dashboard_banner.dart';

/// Banner for the soonest upcoming medication reminder (picked relative to the
/// current time). Tapping it opens the Medications tab. The screen decides
/// whether to show it (only when a reminder is scheduled).
class NextReminderBanner extends StatelessWidget {
  const NextReminderBanner({required this.reminder, super.key});

  final NextReminder reminder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time =
        '${reminder.hour.toString().padLeft(2, '0')}:'
        '${reminder.minute.toString().padLeft(2, '0')}';

    return DashboardBanner(
      icon: Icons.alarm,
      color: AppColors.secondary,
      title: l10n.dashboardNextReminderTitle,
      subtitle: l10n.dashboardNextReminderBody(
        reminder.medicationName,
        time,
        _remaining(context, reminder.timeUntil),
      ),
      onTap: () => context.goNamed(AppRoutes.medications.name),
    );
  }

  /// Human "in Xh Ym" for a sub-24h duration (reminders repeat daily).
  String _remaining(BuildContext context, Duration d) {
    final l10n = context.l10n;
    if (d.inMinutes < 1) return l10n.dashboardRemainingSoon;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return l10n.dashboardRemainingHm(hours, minutes);
    }
    if (hours > 0) return l10n.dashboardRemainingH(hours);
    return l10n.dashboardRemainingM(minutes);
  }
}
