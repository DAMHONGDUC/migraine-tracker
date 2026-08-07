import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/sections/alerts_section.dart';
import '../../../providers.dart';
import '../../widgets/correlation_card.dart';
import '../../widgets/pressure_forecast_card.dart';

/// Everything pressure in one place: what the air is about to do, what it has
/// done to this user so far, and the alert that acts on both. Reached from
/// Insights' `PressureCard` and from the Settings row.
///
/// Full-bleed list because `AlertsSection` is `ListTile`s, which inset
/// themselves; the cards above take the gutter on their own.
class PressureScreen extends ConsumerWidget {
  const PressureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(correlationResultProvider);

    return SdScaffoldV2(
      title: Text(
        context.l10n.pressureScreenTitle,
        style: AppTextStyle.titleLarge,
      ),
      body: ListView(
        padding: SdContentPaddingV2.fullBleed(context),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV2.horizontal,
            ),
            child: Column(
              children: <Widget>[
                const PressureForecastCard(),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                switch (result) {
                  AsyncData(value: final value) => CorrelationCard(
                    result: value,
                  ),
                  _ => const SizedBox.shrink(),
                },
              ],
            ),
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          const AlertsSection(),
        ],
      ),
    );
  }
}
