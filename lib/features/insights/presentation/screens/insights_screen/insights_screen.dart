import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../attacks/providers.dart';
import '../../../../premium/presentation/widgets/premium_gate.dart';
import '../../../../weather/providers.dart';
import '../../../providers.dart';
import '../../widgets/correlation_card.dart';
import '../../widgets/pressure_forecast_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(correlationResultProvider);

    return AppScaffold(
      // Tab screen: content scrolls behind the floating glass nav via
      // AppScaffold.bottomNavInset, so the device inset is already
      // accounted for there — a bottom SafeArea would cut it short.
      withSafeArea: false,
      title: Text(context.l10n.insightsTitle, style: AppTextStyle.titleLarge),
      body: switch (result) {
        AsyncData(value: final value) => AppRefreshIndicator(
          onRefresh: () => AppRefreshIndicator.run(() {
            ref
              ..invalidate(attacksStreamProvider)
              ..invalidate(pressureForecastProvider);
          }),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacingConstant.w16,
              AppScaffold.bodyTopInset(context) + AppSpacingConstant.h16,
              AppSpacingConstant.w16,
              AppScaffold.bottomNavInset(context) + AppSpacingConstant.h16,
            ),
            children: [
              // Free users never build the forecast card, so no forecast is
              // fetched or held for them.
              PremiumGate(
                lockedIcon: Icons.show_chart,
                lockedMessage: context.l10n.premiumLockedForecast,
                child: const PressureForecastCard(),
              ),
              SizedBox(height: AppSpacingConstant.h12),
              CorrelationCard(result: value),
            ],
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
