import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/step_count_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/step_day.dart';
import '../../../health/domain/entities/step_hour.dart';
import '../../../health/domain/enums/health_data_kind.dart';
import '../../../health/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/exertion_correlation_result.dart';
import '../../domain/enums/health_range.dart';
import '../../domain/services/health_range_buckets.dart';
import '../../providers.dart';
import 'exertion_correlation_body.dart';
import 'health_connect_prompt.dart';
import 'health_range_chart.dart';
import 'health_range_selector.dart';
import 'step_correlation_body.dart';

part 'activity_card_analysis.dart';
part 'activity_card_steps.dart';

/// Insights' activity card: what Apple Health counted, then what it means.
///
/// **The step chart on top is free**, like every other reading that only says
/// what HealthKit handed over — it is the answer to "did connecting work", so
/// locking it would leave a user who just flipped the switch looking at
/// nothing. **The analysis below it is premium**, and that now includes the
/// exertion correlation as well as the step one (owner's spec; this moved
/// exertion from free, see `docs/PREMIUM_RULES.md`).
///
/// Not tappable as a whole, unlike before: the card owns a range selector,
/// and a card-level tap would fight it. `/activity` is still reached from its
/// Settings row. No chevron, for the same reason.
class ActivityCard extends ConsumerWidget {
  const ActivityCard({required this.result, super.key});

  final ExertionCorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Off iOS there is no step source at all, so the free half would only
    // ever say "connect", pointing at a switch that is not there.
    final bool hasHealth = ref.watch(healthAvailableProvider);

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // No heading — the tab above the card is it.
            if (hasHealth) ...<Widget>[
              const _StepsSection(),
              SizedBox(height: SdContentPaddingV2.sectionGap),
              const SdDividerV2(),
            ],
            SizedBox(height: SdContentPaddingV2.sectionGap),
            _Analysis(result: result, hasHealth: hasHealth),
          ],
        ),
      ),
    );
  }
}
