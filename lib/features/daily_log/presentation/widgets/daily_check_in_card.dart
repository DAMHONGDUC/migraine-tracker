import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/dashboard_chevron.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../medications/domain/entities/next_reminder.dart';
import '../../../medications/domain/repositories/medication_reminder_repository.dart';
import '../../../medications/domain/services/next_reminder_calculator.dart';
import '../../../medications/providers.dart';
import '../../providers.dart';

/// The dashboard's one ask a day, and — when there is one — the next dose due,
/// in one card.
///
/// **Two rows in one card, not two cards** (owner's call): both are one-line
/// prompts that open one screen each, so they were already drawn the same way
/// — a tinted `SdIconBadgeV2`, an accent name over a muted line, a chevron —
/// and sitting them apart on the same list made the same kind of row read as
/// two kinds of thing. Colour is what still tells them apart: primary for the
/// day's own ask, secondary for a medication.
///
/// **The card is not tappable; each row is.** They open different screens, so
/// one `onTap` over both would have to guess which.
///
/// The check-in row never leaves — a card that vanished on save would read as
/// the app forgetting what it was just told. The reminder row is only there
/// while a reminder is scheduled, and its "in 2h 15m" is why this ticks.
class DailyCheckInCard extends ConsumerStatefulWidget {
  const DailyCheckInCard({super.key});

  @override
  ConsumerState<DailyCheckInCard> createState() => _DailyCheckInCardState();
}

class _DailyCheckInCardState extends ConsumerState<DailyCheckInCard> {
  static const NextReminderCalculator _calculator = NextReminderCalculator();

  /// Recomputes "in 2h 15m" against a fresh now. Half a minute is under the
  /// resolution the line is written at, so it can never show a stale minute.
  static const Duration _tick = Duration(seconds: 30);

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tick, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool done = ref.watch(isTodayCheckedInProvider);
    // Computed here rather than read off `nextReminderProvider`: that one takes
    // its "now" from whenever it last built, and this card owns a ticker that
    // says when now moved on.
    final NextReminder? reminder = _calculator.compute(
      ref.watch(medicationRemindersStreamProvider).value ??
          const <MedicationReminderView>[],
      now: DateTime.now(),
    );

    return SdCardV2(
      child: Column(
        children: <Widget>[
          Semantics(
            button: true,
            label: l10n.dailyLogA11yOpen,
            excludeSemantics: true,
            child: _PromptRow(
              // The glyph carries the state — a tick once the day is answered — and the badge tint stays put, so the row does not change weight when it flips.
              icon: done ? AppIconConstant.saved : AppIconConstant.dailyLog,
              accent: AppColors.primary,
              title: done ? l10n.dailyLogCardDone : l10n.dailyLogCardPrompt,
              subtitle: done
                  ? l10n.dailyLogCardDoneBody
                  : l10n.dailyLogCardPromptBody,
              onTap: () => context.pushNamed<void>(AppRoutes.dailyLog.name),
            ),
          ),
          if (reminder != null) ...<Widget>[
            const SdDividerV2(),
            _PromptRow(
              icon: AppIconConstant.medication,
              accent: AppColors.secondary,
              title: reminder.medicationName,
              subtitle: l10n.dashboardNextReminderWhen(
                DateTimeUtils.hhmm(reminder.hour, reminder.minute),
                _remaining(l10n, reminder.timeUntil),
              ),
              // Straight to the medication's detail screen — that's where it can be changed.
              onTap: () => context.pushNamed(
                AppRoutes.medication.name,
                pathParameters: <String, String>{
                  AppRoutes.medicationIdParam: reminder.medicationId,
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Human "in Xh Ym" for a sub-24h duration (reminders repeat daily).
  String _remaining(AppLocalizations l10n, Duration until) {
    final int hours = until.inHours;
    final int minutes = until.inMinutes % 60;

    if (until.inMinutes < 1) return l10n.dashboardRemainingSoon;
    if (hours > 0 && minutes > 0)
      return l10n.dashboardRemainingHm(hours, minutes);
    if (hours > 0) return l10n.dashboardRemainingH(hours);
    return l10n.dashboardRemainingM(minutes);
  }
}

/// One row of the card: badge, an accent line over a muted one, chevron.
///
/// Both rows are this, so the day's ask and the next dose cannot drift into
/// two shapes again. The ink splashes on the card's own `Material` and is
/// clipped to its radius, which is why the row needs no surface of its own.
class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Row(
          children: <Widget>[
            SdIconBadgeV2(icon: icon, color: accent),
            SizedBox(width: SdSpacingConstant.w16),
            // Separate prompt and detail so neither depends on colour for emphasis.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyle.bodyLarge.w600.copyWith(color: accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SdSpacingConstant.h2),
                  Text(
                    subtitle,
                    style: AppTextStyle.bodySmall.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            const DashboardChevron(),
          ],
        ),
      ),
    );
  }
}
