import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/sleep_correlation_result.dart';
import '../../providers.dart';
import 'insight_progress_body.dart';
import 'insight_settling_note.dart';

part 'sleep_correlation_body_insight.dart';
part 'sleep_correlation_body_not_connected.dart';
part 'sleep_correlation_body_no_variation.dart';

/// What the sleep analysis found: did attacks follow the short nights?
///
/// Cardless, because the summary card on Insights and the sleep detail screen
/// both draw it. Premium either way: a free user never builds it, so no
/// HealthKit read is issued for them at all.
///
/// While the read is in flight it renders nothing rather than a spinner: a
/// card that pops in half a second later is calmer than one that flickers a
/// placeholder first.
class SleepCorrelationBody extends ConsumerWidget {
  const SleepCorrelationBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SleepCorrelationResult> value = ref.watch(
      sleepCorrelationProvider,
    );

    return switch (value) {
      AsyncData(value: final SleepCorrelationResult value) => switch (value) {
        SleepNotConnected() => const _NotConnected(),
        final SleepInsufficientData r => InsightProgressBody(
          icon: Icons.hourglass_empty,
          message: context.l10n.insightsSleepInsufficientData(
            r.requiredNights,
            r.requiredPerGroup,
          ),
          progress: r.nightsWithSleep / r.requiredNights,
          caption: context.l10n.insightsSleepProgressCaption(
            r.nightsWithSleep,
            r.requiredNights,
          ),
        ),
        SleepNoVariation() => const _SleepNoVariationBody(),
        final SleepInsight r => _SleepInsightBody(result: r),
      },
      // A HealthKit failure is not worth an error state on a secondary card.
      _ => const SizedBox.shrink(),
    };
  }
}
