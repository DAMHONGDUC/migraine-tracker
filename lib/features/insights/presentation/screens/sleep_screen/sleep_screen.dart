import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/premium_gate.dart';
import '../../../../../core/widgets/sections/health_connection_tile.dart';
import '../../../../health/domain/enums/health_data_kind.dart';
import '../../../../health/providers.dart';
import '../../widgets/sleep_correlation_card.dart';
import '../../widgets/sleep_summary_card.dart';

/// The sleep insight and the switch that lets the app read it. Its own screen,
/// not folded in with activity: the night is a different question from the day.
///
/// Controls first, cards last: the switch is what the user came to change.
/// Full-bleed list because it is a `ListTile`, which insets itself; the card
/// takes the gutter on its own.
class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdScaffoldV2(
      title: Text(
        context.l10n.sleepScreenTitle,
        style: AppTextStyle.titleLarge,
      ),
      body: ListView(
        padding: SdContentPaddingV2.fullBleed(context),
        children: <Widget>[
          HealthConnectionTile(
            kind: HealthDataKind.sleep,
            icon: AppIconConstant.sleep,
            title: context.l10n.healthSleepTitle,
          ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV2.horizontal,
            ),
            child: Column(
              children: <Widget>[
                // What was read comes before what is drawn from it. Always
                // mounted — the card hides itself while sleep is
                // disconnected, and mounting it on the flag instead cost a
                // mid-build provider flush (see [SleepSummaryCard]).
                const SleepSummaryCard(),
                if (ref.watch(healthControllerProvider).sleep)
                  SizedBox(height: SdContentPaddingV2.sectionGap),
                PremiumGate(
                  lockedIcon: AppIconConstant.sleep,
                  lockedMessage: context.l10n.premiumLockedSleep,
                  child: const SleepCorrelationCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
