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
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../core/widgets/weather/weather_attribution.dart';
import '../../../premium/providers.dart';
import '../../../weather/domain/entities/pressure_forecast.dart';
import '../../../weather/providers.dart';

part 'pressure_forecast_body_chart.dart';

/// Single-series line chart: pressure over now−12h … now+48h.
class PressureForecastBody extends ConsumerWidget {
  const PressureForecastBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cardless: this body is always drawn inside someone else's card, so a `PremiumGate` here would put a card inside a card.
    if (!ref.watch(hasPremiumProvider)) {
      return PremiumUnlockPrompt(message: context.l10n.premiumLockedForecast);
    }

    final forecast = ref.watch(pressureForecastProvider);

    return switch (forecast) {
          // Show attribution only with weather data.
      AsyncData(value: final value) when value != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Chart(forecast: value),
          SizedBox(height: SdSpacingConstant.h4),
          const WeatherAttribution(),
        ],
      ),
      // No attribution on this one: the mark is owed by the state that actually drew Apple's data, and a placeholder drew none.
      AsyncLoading() => const SdChartSkeletonV2(),
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
