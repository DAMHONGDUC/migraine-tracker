import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import 'insight_card.dart';
import 'pressure_forecast_body.dart';

/// The forecast on its own card, as the pressure detail screen shows it.
/// Insights folds this into `PressureCard` alongside the correlation instead.
class PressureForecastCard extends StatelessWidget {
  const PressureForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsForecastTitle,
      child: const PressureForecastBody(),
    );
  }
}
