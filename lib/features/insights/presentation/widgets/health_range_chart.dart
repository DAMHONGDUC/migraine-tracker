import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/health_range.dart';
import '../../domain/services/health_range_buckets.dart';

/// The bar chart under a [HealthRangeSelector], for steps and for sleep
/// alike.
///
/// One widget for both, so a range means the same thing on either card. What
/// differs is passed in: the colour, and how a value is worded.
class HealthRangeChart extends StatelessWidget {
  const HealthRangeChart({
    required this.buckets,
    required this.range,
    required this.color,
    required this.tooltip,
    required this.semanticsLabel,
    super.key,
  });

  final List<HealthBucket> buckets;
  final HealthRange range;
  final Color color;

  /// Words a bar's value — "8,234 steps", "7h 20m".
  final String Function(num value) tooltip;

  /// What the chart is, for VoiceOver: bars themselves say nothing.
  final String semanticsLabel;

  /// Above this many bars the labels are dropped rather than overlapped — 30
  /// day-of-month numbers do not fit the card's width, and a smear of digits
  /// under the axis is worse than none.
  static const int _maxLabelledBars = 14;

  /// How a bucket's start reads under its bar.
  String _label(AppLocalizations l10n, DateTime start) => switch (range) {
    HealthRange.day => DateFormat.j(l10n.localeName).format(start),
    HealthRange.week => DateFormat.E(l10n.localeName).format(start),
    HealthRange.month => DateFormat.d(l10n.localeName).format(start),
    HealthRange.halfYear => DateFormat.MMMd(l10n.localeName).format(start),
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool labelled = buckets.length <= _maxLabelledBars;

    if (buckets.isEmpty) {
      return SizedBox(
        height: SdChartStyleV2.plotHeight,
        child: Center(
          child: Text(
            l10n.healthRangeEmpty,
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ),
      );
    }

    // Not SdChartFrameV2: that one carries a title, and the card heading plus
    // the range selector already say what this is — a third label above the
    // bars would be the same fact stated twice.
    return Semantics(
      container: true,
      label: semanticsLabel,
      // Bars say nothing to VoiceOver; the label above stands in for them.
      child: ExcludeSemantics(
        child: SizedBox(
          height: SdChartStyleV2.plotHeight,
          child: SdBarChartV2(
            bars: <SdBarV2>[
              for (final HealthBucket bucket in buckets)
                SdBarV2(
                  value: bucket.value,
                  label: labelled ? _label(l10n, bucket.start) : '',
                ),
            ],
            color: color,
            tooltip: tooltip,
          ),
        ),
      ),
    );
  }
}
