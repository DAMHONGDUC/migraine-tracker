import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/health_connection_tile.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/sleep_night.dart';
import '../../../health/domain/enums/health_data_kind.dart';
import '../../../health/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/enums/health_range.dart';
import '../../domain/services/health_range_buckets.dart';
import '../../providers.dart';
import 'health_range_chart.dart';
import 'health_range_selector.dart';
import 'insight_card.dart';
import 'insight_info_sheet.dart';
import 'sleep_correlation_body.dart';

part 'sleep_card_analysis.dart';
part 'sleep_card_nights.dart';

/// Insights' sleep tab: what Apple Health recorded, then what it means — a
/// card each, the same split as the activity tab.
class SleepCard extends ConsumerWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // No title on either — the tab above them is it.
        const InsightCard(child: _NightsSection()),
        SizedBox(height: SdContentPaddingV2.sectionGap),
        const _Analysis(),
      ],
    );
  }
}
