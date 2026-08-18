import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/step_count_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/step_day.dart';
import '../../../health/domain/entities/step_summary.dart';
import '../../../health/providers.dart';
import 'insight_value_row.dart';

part 'step_summary_card_chart.dart';

/// What Apple Health actually counted: today, the week's average, and the
/// days behind them.
///
/// Free, unlike the correlation card under it — same reason as
/// [SleepSummaryCard]: it is the answer to "did connecting work".
///
/// Absent entirely while steps are disconnected.
class StepSummaryCard extends ConsumerWidget {
  const StepSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<StepSummary> summary = ref.watch(stepSummaryProvider);

    return switch (summary) {
      AsyncData<StepSummary>(value: final StepSummary value) =>
        value.isEmpty
            ? _Empty(message: l10n.stepsSummaryEmpty)
            : _Loaded(summary: value),
      // A read that failed and a read that returned nothing are the same
      // thing to the user — iOS never says which (see HealthRepository).
      AsyncError<StepSummary>() => _Empty(message: l10n.stepsSummaryEmpty),
      // The card's own shape rather than a spinner in a box: this sits in a
      // scrolling column, so a placeholder of the wrong height moves
      // everything below it when the read returns.
      _ => const SdChartCardSkeletonV2(),
    };
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.summary});

  final StepSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.stepsSummaryLatest,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              summary.latest!.count.label(l10n),
              style: AppTextStyle.displaySmall.w600,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            InsightValueRow(
              label: l10n.stepsSummaryAverage,
              value: summary.average.label(l10n),
            ),
            SizedBox(height: SdSpacingConstant.h20),
            _WeekChart(days: summary.days),
          ],
        ),
      ),
    );
  }
}

/// Connected, but nothing came back — no samples on this device, or the read
/// was refused and iOS will not say which.
class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Text(message, style: AppTextStyle.bodyMedium.secondary),
      ),
    );
  }
}
