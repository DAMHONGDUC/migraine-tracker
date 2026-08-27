import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../core/widgets/sections/health_connection_tile.dart';
import '../../../../health/domain/enums/health_data_kind.dart';
import '../../../../health/providers.dart';
import '../../../providers.dart';
import '../../widgets/exertion_correlation_card.dart';
import '../../widgets/step_correlation_card.dart';
import '../../widgets/step_summary_card.dart';

/// Everything about how much the user moved: the exertion they reported, the
/// steps their phone counted, and the switch that lets the app read them.
///
/// Controls first, cards last: the switch is what the user came to change.
/// Full-bleed list because it is a `ListTile`, which insets itself; the cards
/// take the gutter on their own.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(exertionCorrelationResultProvider);

    return SdScaffoldV2(
      title: Text(
        context.l10n.insightsActivityTitle,
        style: AppTextStyle.titleLarge,
      ),
      body: ListView(
        padding: SdContentPaddingV2.fullBleed(context),
        children: <Widget>[
          // Steps only: the exertion half is typed in by hand, it reads nothing.
          HealthConnectionTile(
            kind: HealthDataKind.steps,
            icon: Icons.directions_walk,
            title: context.l10n.healthStepsTitle,
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV2.horizontal,
            ),
            child: Column(
              children: <Widget>[
                // What was counted comes before what is drawn from it. Always
                // mounted — the card hides itself while steps are
                // disconnected, and mounting it on the flag instead cost a
                // mid-build provider flush (see [SleepSummaryCard]).
                const StepSummaryCard(),
                if (ref.watch(healthControllerProvider).steps)
                  SizedBox(height: SdContentPaddingV2.sectionGap),
                switch (result) {
                  AsyncData(value: final value) => ExertionCorrelationCard(
                    result: value,
                  ),
                  _ => const SizedBox.shrink(),
                },
                SizedBox(height: SdContentPaddingV2.sectionGap),
                PremiumGate(
                  lockedIcon: Icons.directions_walk,
                  lockedMessage: context.l10n.premiumLockedSteps,
                  child: const StepCorrelationCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
