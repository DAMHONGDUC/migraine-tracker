import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/sleep_correlation_result.dart';
import '../../providers.dart';
import 'insight_card.dart';
import 'insight_progress_body.dart';

part 'sleep_correlation_card_insight.dart';
part 'sleep_correlation_card_not_connected.dart';
part 'sleep_correlation_card_no_variation.dart';

/// Stat tile for the sleep insight: did attacks follow the short nights?
///
/// The whole card is premium (the Insights screen wraps it in a
/// `PremiumGate`), so unlike the pressure card there is no free branch and no
/// teaser — a free user never builds it and no HealthKit read is issued for
/// them at all.
///
/// While the read is in flight the card renders nothing rather than a
/// spinner: a card that pops in half a second later is calmer than one that
/// flickers a placeholder first.
class SleepCorrelationCard extends ConsumerWidget {
  const SleepCorrelationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SleepCorrelationResult> result = ref.watch(
      sleepCorrelationProvider,
    );

    return switch (result) {
      AsyncData(value: final SleepCorrelationResult value) => _Card(
        result: value,
      ),
      // A HealthKit failure is not worth an error state on a secondary card.
      _ => const SizedBox.shrink(),
    };
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.result});

  final SleepCorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsSleepTitle,
      child: switch (result) {
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
    );
  }
}
