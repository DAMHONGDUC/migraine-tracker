import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../attacks/providers.dart';
import '../../../../health/providers.dart';
import '../../../../weather/providers.dart';
import '../../../domain/entities/correlation_result.dart';
import '../../../domain/entities/exertion_correlation_result.dart';
import '../../../domain/enums/insights_tab.dart';
import '../../../providers.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/pressure_card.dart';
import '../../widgets/sleep_card.dart';
import '../../widgets/weather_card.dart';

part 'insights_screen_body.dart';

/// One card at a time, behind a segmented switch under the app bar.
///
/// The four used to stack in one scroll view, which made the screen a long
/// column of unrelated subjects and left the card a user came for several
/// screens down. A tab per card is the same content with a way to aim at it.
///
/// **The strip is built from the tabs that exist, not from the enum.** Sleep
/// is absent off iOS, so it is four segments there and three elsewhere, and
/// nothing offers a tab that could only say "unavailable".
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<InsightsTab> tabs = <InsightsTab>[
      InsightsTab.weather,
      InsightsTab.pressure,
      InsightsTab.activity,
      // iOS only: off HealthKit there is no sleep source at all.
      if (ref.watch(healthAvailableProvider)) InsightsTab.sleep,
    ];
    // Fall back rather than trust the stored tab: Sleep leaves the list off
    // iOS, and indexing a shorter strip with it would throw.
    final InsightsTab watched = ref.watch(insightsTabProvider);
    final InsightsTab selected = tabs.contains(watched) ? watched : tabs.first;

    return SdScaffoldV2(
      title: Text(l10n.insightsTitle, style: AppTextStyle.titleLarge),
      body: Column(
        children: <Widget>[
          Padding(
            // Clears the app bar; the card below still scrolls under it.
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              SdContentPaddingV2.top(context),
              SdContentPaddingV2.horizontal,
              0,
            ),
            child: SdSegmentedTabsV2(
              selectedIndex: tabs.indexOf(selected),
              onSelected: (int index) =>
                  ref.read(insightsTabProvider.notifier).set(tabs[index]),
              segments: <SdSegmentV2>[
                for (final InsightsTab tab in tabs)
                  SdSegmentV2(label: _label(l10n, tab)),
              ],
            ),
          ),
          Expanded(child: _TabBody(tab: selected)),
        ],
      ),
    );
  }

  /// A tab's name is its card's name — one string for both, so the segment
  /// and the heading under it can never come to disagree.
  String _label(AppLocalizations l10n, InsightsTab tab) => switch (tab) {
    InsightsTab.weather => l10n.weatherCardTitle,
    InsightsTab.pressure => l10n.insightsPressureTitle,
    InsightsTab.activity => l10n.activityCardTitle,
    InsightsTab.sleep => l10n.sleepCardTitle,
  };
}
