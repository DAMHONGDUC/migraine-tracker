import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/chart_axis_utils.dart';
import '../../domain/entities/pressure_timeline.dart';
import '../../domain/services/pressure_timeline_builder.dart';
import '../../providers.dart';

part 'pressure_history_body_chart.dart';

/// The correlation card's sentence, drawn.
class PressureHistoryBody extends ConsumerWidget {
  const PressureHistoryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final PressureTimeline timeline = ref.watch(pressureTimelineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.insightsPressureHistoryTitle,
          style: AppTextStyle.titleSmall,
        ),
        SizedBox(height: SdSpacingConstant.h12),
        if (timeline.isEmpty)
          Text(
            l10n.insightsPressureHistoryEmpty,
            style: AppTextStyle.bodySmall.secondary,
          )
        else ...<Widget>[
          _Chart(timeline: timeline),
          // Said rather than silently dropped: a user counting dots against their own memory deserves to know why the two disagree.
          if (timeline.attacksWithoutReading > 0) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              // Once more attacks are missing than are shown, the count stops informing and starts looking like a fault.
              timeline.strandedOutweighsPlotted
                  ? l10n.insightsPressureHistoryYoung
                  : l10n.insightsPressureHistoryStranded(
                      timeline.attacksWithoutReading,
                    ),
              style: AppTextStyle.labelSmall.secondary,
            ),
          ],
        ],
      ],
    );
  }
}
