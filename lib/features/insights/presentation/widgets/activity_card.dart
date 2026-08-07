import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../health/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/exertion_correlation_result.dart';
import 'exertion_correlation_body.dart';
import 'insight_card.dart';
import 'step_correlation_body.dart';

/// Insights' one activity entry: what the user reported doing and what their
/// phone counted, on a single card. Both are the same question asked twice —
/// how much did you move — so they read as one thing, unlike sleep.
///
/// Tappable for everyone, because the exertion half is free; the step half
/// shows its pitch until premium.
class ActivityCard extends ConsumerWidget {
  const ActivityCard({required this.result, super.key});

  final ExertionCorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    return InsightCard(
      title: context.l10n.insightsActivityTitle,
      trailing: hasPremium ? null : const PremiumBadge(),
      onTap: () => context.pushNamed(AppRoutes.activity.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExertionCorrelationBody(result: result),
          // iOS only: off HealthKit there is no step source, so the half would
          // only ever say "connect", pointing at a switch that isn't there.
          if (ref.watch(healthAvailableProvider)) ...<Widget>[
            SizedBox(height: SdContentPaddingV2.sectionGap),
            // Free users never build the step body, so no HealthKit read is
            // issued for them — they get the pitch in its place.
            if (hasPremium)
              const StepCorrelationBody()
            else
              Text(
                context.l10n.premiumLockedSteps,
                style: AppTextStyle.bodyMedium,
              ),
          ],
        ],
      ),
    );
  }
}
