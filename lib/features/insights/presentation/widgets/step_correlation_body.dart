import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/step_count_label.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/step_correlation_result.dart';
import '../../providers.dart';
import 'insight_body_skeleton.dart';
import 'insight_progress_body.dart';
import 'insight_settling_note.dart';

part 'step_correlation_body_insight.dart';
part 'step_correlation_body_not_connected.dart';
part 'step_correlation_body_no_variation.dart';

/// What the step analysis found: did attacks follow the low-activity days?
class StepCorrelationBody extends ConsumerWidget {
  const StepCorrelationBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<StepCorrelationResult> result = ref.watch(
      stepCorrelationProvider,
    );

    return switch (result) {
      AsyncData(value: final StepCorrelationResult value) => switch (value) {
        StepNotConnected() => const _StepNotConnected(),
        final StepInsufficientData r => InsightProgressBody(
          icon: AppIconConstant.steps,
          message: context.l10n.insightsStepsInsufficientData(
            r.requiredDays,
            r.requiredPerGroup,
          ),
          progress: r.daysWithSteps / r.requiredDays,
          caption: context.l10n.insightsStepsProgressCaption(
            r.daysWithSteps,
            r.requiredDays,
          ),
        ),
        StepNoVariation() => const _StepNoVariationBody(),
        final StepInsight r => _StepInsightBody(result: r),
      },
      // The read is HealthKit's, which takes as long as it takes — drawn in the shape it will resolve into rather than left blank.
      AsyncLoading<dynamic>() => const InsightBodySkeleton(),
      // A HealthKit failure is not worth an error state on a secondary card.
      _ => const SizedBox.shrink(),
    };
  }
}
