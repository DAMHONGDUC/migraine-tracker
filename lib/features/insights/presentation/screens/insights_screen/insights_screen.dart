import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../attacks/providers.dart';
import '../../../../health/providers.dart';
import '../../../../weather/providers.dart';
import '../../../providers.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/pressure_card.dart';
import '../../widgets/sleep_correlation_card.dart';
import '../../widgets/weather_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(correlationResultProvider);
    final exertionResult = ref.watch(exertionCorrelationResultProvider);

    return SdScaffoldV2(
      title: Text(context.l10n.insightsTitle, style: AppTextStyle.titleLarge),
      body: switch ((result, exertionResult)) {
        (AsyncData(value: final value), AsyncData(value: final exertionValue)) =>
          SdRefreshIndicatorV2(
            onRefresh: () => SdRefreshIndicatorV2.run(() {
              ref
                ..invalidate(attacksStreamProvider)
                ..invalidate(pressureForecastProvider)
                ..invalidate(weatherReportProvider)
                ..invalidate(sleepCorrelationProvider)
                ..invalidate(stepCorrelationProvider);
            }),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: SdContentPaddingV2.screen(context, floatingNav: true),
              children: [
                // Card 1: the weather, free for everyone, with the alert it
                // drives set from the card itself. The pressure correlation
                // stays below it — the reading and the analysis of it are
                // different questions, and one card carrying both was already
                // the longest on the screen.
                const WeatherCard(),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                PressureCard(result: value),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                // Exertion + steps on one card: both ask how much the user
                // moved. Sleep stays its own — the night is another question.
                ActivityCard(result: exertionValue),
                // iOS only: off HealthKit there is no sleep source, so the card would only say "unavailable".
                if (ref.watch(healthAvailableProvider)) ...<Widget>[
                  SizedBox(height: SdContentPaddingV2.sectionGap),
                  PremiumGate(
                    lockedIcon: Symbols.bedtime,
                    lockedMessage: context.l10n.premiumLockedSleep,
                    child: SleepCorrelationCard(
                      onTap: () => context.pushNamed(AppRoutes.sleep.name),
                    ),
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
