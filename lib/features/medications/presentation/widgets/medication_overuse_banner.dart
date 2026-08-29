import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../insights/domain/entities/medication_overuse_result.dart';
import '../../../insights/providers.dart';

/// The count nobody makes for themselves: how many days this month acute
/// medication was taken, and what happens past the line.
///
/// **Free, and never behind a gate.** Every other analysis in the app is
/// something the user gains by paying; this one is a harm they avoid by
/// being told, and `docs/PREMIUM_RULES.md` has no room for selling that.
///
/// It is a warning and never a diagnosis. Medication-overuse headache needs
/// the pattern held for more than three months plus a clinician, so the copy
/// says what the count is and what it can lead to, and stops.
class MedicationOveruseBanner extends ConsumerWidget {
  const MedicationOveruseBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MedicationOveruseResult result = ref.watch(medicationOveruseProvider);

    // Silent below the warning line, on purpose: a banner that appears every
    // month is one the user stops reading before the month it matters.
    if (result.risk == MedicationOveruseRisk.none) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final bool atRisk = result.risk == MedicationOveruseRisk.atRisk;
    // Amber at both grades, never the error red. This is a course someone can
    // still change, and an alarm over a month they cannot undo reads as blame.
    final Color color = context.colorScheme.tertiary;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SdIconV2(
              icon: AppIconConstant.info,
              size: AppIconSize.row,
              color: color,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.medicationOveruseTitle(result.currentMonthDays),
                    style: AppTextStyle.titleSmall.copyWith(color: color),
                  ),
                  SizedBox(height: SdSpacingConstant.h4),
                  Text(
                    atRisk
                        ? l10n.medicationOveruseAtRisk(result.thresholdDays)
                        : l10n.medicationOveruseApproaching(
                            result.thresholdDays,
                          ),
                    style: AppTextStyle.bodySmall.secondary,
                  ),
                  // Only once the run is long enough to be the pattern ICHD-3
                  // describes. One heavy month is a bad month.
                  if (result.isSustained) ...<Widget>[
                    SizedBox(height: SdSpacingConstant.h4),
                    Text(
                      l10n.medicationOveruseSustained(
                        result.consecutiveMonthsAtRisk,
                      ),
                      style: AppTextStyle.bodySmall.copyWith(color: color),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
