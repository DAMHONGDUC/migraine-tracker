import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/health_connection_tile.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/enums/health_data_kind.dart';
import '../../../health/providers.dart';

/// The cycle half of the check-in: the connect switch, and what Apple Health says about today.
///
/// It asks nothing. The cycle is already recorded in Health, and asking the
/// user to type it again here is asking twice for something the phone already
/// knows. Nothing it reads is stored — see `features/health/CLAUDE.md`.
class DailyCycleSection extends ConsumerWidget {
  const DailyCycleSection({super.key});

  /// Day 0 is the start itself, so the period's own days read 1, 2, 3 — how a person counts them.
  String _statusOf(int? dayInCycle, bool hasData, AppLocalizations l10n) {
    if (dayInCycle == null) {
      return hasData ? l10n.dailyLogCycleOutside : l10n.dailyLogCycleNone;
    }
    if (dayInCycle < 0) return l10n.dailyLogCycleBefore(-dayInCycle);
    if (dayInCycle == 0) return l10n.dailyLogCycleStart;
    return l10n.dailyLogCycleDay(dayInCycle + 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // Off iOS there is no HealthKit to connect to, and the section would be a switch that does nothing.
    if (!ref.watch(healthAvailableProvider)) return const SizedBox.shrink();

    final bool connected = ref.watch(healthControllerProvider).cycle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.dailyLogCycleSection, style: AppTextStyle.titleSmall),
        SizedBox(height: SdSpacingConstant.h12),
        HealthConnectionTile(
          kind: HealthDataKind.cycle,
          icon: AppIconConstant.cycle,
          title: l10n.healthCycleTitle,
        ),
        // Only once there is a source to say anything about.
        if (connected) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            _statusOf(
              ref.watch(todayCycleDayProvider),
              (ref.watch(cycleDaysProvider).value ?? const <Object>[])
                  .isNotEmpty,
              l10n,
            ),
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
