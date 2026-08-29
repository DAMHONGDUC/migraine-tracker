import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/sleep_night.dart';
import '../../../health/domain/entities/sleep_summary.dart';
import '../../../health/providers.dart';
import 'insight_value_row.dart';

part 'sleep_summary_card_chart.dart';

/// What Apple Health actually handed over: last night, the week's average, and the nights behind them.
class SleepSummaryCard extends ConsumerWidget {
  const SleepSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    // Watched before the connection flag, never after: this listener is what keeps the provider flushed between frames.
    final AsyncValue<SleepSummary> summary = ref.watch(sleepSummaryProvider);

    if (!ref.watch(healthControllerProvider).sleep) {
      return const SizedBox.shrink();
    }

    return switch (summary) {
      AsyncData<SleepSummary>(value: final SleepSummary value) =>
        value.isEmpty
            ? _Empty(message: l10n.sleepSummaryEmpty)
            : _Loaded(summary: value),
      // A read that failed and a read that returned nothing are the same thing to the user — iOS never says which (see HealthRepository).
      AsyncError<SleepSummary>() => _Empty(message: l10n.sleepSummaryEmpty),
      // The card's own shape rather than a spinner in a box.
      _ => const SdChartCardSkeletonV2(),
    };
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.summary});

  final SleepSummary summary;

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
              l10n.sleepSummaryLatest,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              summary.latest!.duration.label(l10n),
              style: AppTextStyle.displaySmall.w600,
            ),
            SizedBox(height: SdSpacingConstant.h16),
            InsightValueRow(
              label: l10n.sleepSummaryAverage,
              value: summary.average.label(l10n),
            ),
            SizedBox(height: SdSpacingConstant.h20),
            _WeekChart(nights: summary.nights),
          ],
        ),
      ),
    );
  }
}

/// Connected, but nothing came back — no samples on this device, or the read was refused and iOS will not say which.
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
