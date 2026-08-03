import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../attacks/providers.dart';
import '../../../../health/providers.dart';
import '../../../../weather/providers.dart';
import '../../../providers.dart';
import '../../widgets/correlation_card.dart';
import '../../widgets/pressure_forecast_card.dart';
import '../../widgets/sleep_correlation_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(correlationResultProvider);

    return SdScaffoldV2(
      title: Text(context.l10n.insightsTitle, style: AppTextStyle.titleLarge),
      body: switch (result) {
        AsyncData(value: final value) => SdRefreshIndicatorV2(
          onRefresh: () => SdRefreshIndicatorV2.run(() {
            ref
              ..invalidate(attacksStreamProvider)
              ..invalidate(pressureForecastProvider)
              ..invalidate(sleepCorrelationProvider);
          }),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: SdContentPaddingV2.screen(context, floatingNav: true),
            children: [
              // Free users never build the forecast card, so no forecast is
              // fetched or held for them.
              PremiumGate(
                lockedIcon: Symbols.show_chart,
                lockedMessage: context.l10n.premiumLockedForecast,
                child: const PressureForecastCard(),
              ),
              SizedBox(height: SdSpacingConstant.h12),
              CorrelationCard(result: value),
              // iOS only: off HealthKit there is no sleep source, so the
              // card would have nothing to say but "unavailable".
              if (ref.watch(healthAvailableProvider)) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h12),
                PremiumGate(
                  lockedIcon: Symbols.bedtime,
                  lockedMessage: context.l10n.premiumLockedSleep,
                  child: const SleepCorrelationCard(),
                ),
              ],
            ],
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
