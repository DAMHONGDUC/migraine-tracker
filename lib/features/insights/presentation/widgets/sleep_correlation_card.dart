import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/sleep_correlation_result.dart';
import '../../providers.dart';

part 'sleep_correlation_card_insight.dart';
part 'sleep_correlation_card_insufficient_data.dart';
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.insightsSleepTitle,
              style: AppTextStyle.titleMedium,
            ),
            SizedBox(height: AppSpacingConstant.h16),
            switch (result) {
              SleepNotConnected() => const _NotConnected(),
              final SleepInsufficientData r => _SleepInsufficientDataBody(
                result: r,
              ),
              SleepNoVariation() => const _SleepNoVariationBody(),
              final SleepInsight r => _SleepInsightBody(result: r),
            },
          ],
        ),
      ),
    );
  }
}
