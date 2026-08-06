import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../medications/domain/services/next_reminder_calculator.dart';
import '../../../medications/providers.dart';
import 'highlighted_time_text.dart';

/// Banner for the soonest upcoming medication reminder (picked relative to the
/// current time), tapping through to that medication's detail screen.
///
/// Live without a stream-driven clock provider: a widget-owned 30s timer
/// re-ticks "now" locally. (A `StreamProvider` clock that a synchronous
/// provider watched crashed with "setState during build" when a consumer
/// resumed mid-layout — the timer stays on the element, cancelled on dispose.)
class NextReminderBanner extends ConsumerStatefulWidget {
  const NextReminderBanner({super.key});

  @override
  ConsumerState<NextReminderBanner> createState() => _NextReminderBannerState();
}

class _NextReminderBannerState extends ConsumerState<NextReminderBanner> {
  static const _calculator = NextReminderCalculator();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final views =
        ref.watch(medicationRemindersStreamProvider).value ?? const [];
    final reminder = _calculator.compute(views, now: DateTime.now());
    if (reminder == null) return const SizedBox.shrink();

    final time =
        '${reminder.hour.toString().padLeft(2, '0')}:'
        '${reminder.minute.toString().padLeft(2, '0')}';
    final remaining = _remaining(context, reminder.timeUntil);
    final subtitle = l10n.dashboardNextReminderBody(
      reminder.medicationName,
      time,
      remaining,
    );

    return SdBannerV2(
      icon: Icons.alarm,
      color: AppColors.secondary,
      title: l10n.dashboardNextReminderTitle,
      subtitle: subtitle,
      // Gently highlight the live countdown within the line.
      subtitleChild: HighlightedTimeText(
        full: subtitle,
        highlight: remaining,
        color: AppColors.secondary,
      ),
      // Straight to the medication's detail screen — that's where it can be changed.
      onTap: () => context.pushNamed(
        AppRoutes.medication.name,
        pathParameters: <String, String>{
          AppRoutes.medicationIdParam: reminder.medicationId,
        },
      ),
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
