import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/sleep_night.dart';
import '../../../health/domain/enums/health_data_kind.dart';
import '../../../health/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/enums/health_range.dart';
import '../../domain/services/health_range_buckets.dart';
import '../../providers.dart';
import 'health_connect_prompt.dart';
import 'health_range_chart.dart';
import 'health_range_selector.dart';
import 'sleep_correlation_body.dart';

part 'sleep_card_analysis.dart';
part 'sleep_card_nights.dart';

/// Insights' sleep card: what Apple Health recorded, then what it means.
class SleepCard extends ConsumerWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // No heading — the tab above the card is it.
            const _NightsSection(),
            SizedBox(height: SdContentPaddingV2.sectionGap),
            const SdDividerV2(),
            SizedBox(height: SdContentPaddingV2.sectionGap),
            const _Analysis(),
          ],
        ),
      ),
    );
  }
}
