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
import 'insight_card.dart';
import 'step_correlation_body.dart';

part 'activity_card_analysis.dart';
part 'activity_card_steps.dart';

/// Insights' activity tab: what Apple Health counted, then what it means —
/// a card each (owner's call).
///
/// The two were one card split by a divider, which made a reading and the
/// analysis drawn from it read as one long section. A card is the app's unit
/// of "one subject", so the measurement and the conclusion each get one.
class ActivityCard extends ConsumerWidget {
  const ActivityCard({required this.result, super.key});

  final ExertionCorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Off iOS there is no step source at all, so the free half would only ever say "connect", pointing at a switch that is not there.
    final bool hasHealth = ref.watch(healthAvailableProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // No title on either — the tab above them is it.
        if (hasHealth) ...<Widget>[
          const InsightCard(child: _StepsSection()),
          SizedBox(height: SdContentPaddingV2.sectionGap),
        ],
        InsightCard(child: _Analysis(result: result, hasHealth: hasHealth)),
      ],
    );
  }
}
