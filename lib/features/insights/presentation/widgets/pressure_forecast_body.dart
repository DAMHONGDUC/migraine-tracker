import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/chart_axis_utils.dart';
import '../../../weather/domain/entities/pressure_forecast.dart';
import '../../../weather/providers.dart';

part 'pressure_forecast_body_chart.dart';

/// Single-series line chart: pressure over now−12h … now+48h. The dimmed
/// segment is the past, the solid one the forecast; a vertical marker
/// splits them at "now". No legend — the card's title names the one series.
///
/// Cardless, because two places draw it: `PressureForecastCard` on the
/// detail screen, and `PressureCard` folded in with the correlation.
class PressureForecastBody extends ConsumerWidget {
  const PressureForecastBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(pressureForecastProvider);

    return switch (forecast) {
      AsyncData(value: final value) when value != null => _Chart(
        forecast: value,
      ),
      AsyncLoading() => SizedBox(
        height: SdSpacingConstant.h160,
        child: const Center(child: CircularProgressIndicator()),
      ),
      _ => SizedBox(
        height: SdSpacingConstant.h64,
        child: Center(
          child: Text(
            context.l10n.insightsForecastUnavailable,
            style: AppTextStyle.bodyMedium.secondary,
          ),
        ),
      ),
    };
  }
}
