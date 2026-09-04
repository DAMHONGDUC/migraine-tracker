import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/map_factor_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/analysis_info_sheet.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/factor_association.dart';
import '../../providers.dart';
import 'insight_card.dart';

part 'factors_card_groups.dart';

/// Insights' factors tab: which days bring attacks on, and which keep them away.
///
/// The whole tab is one card, unlike pressure and activity: there is no reading
/// to show beside the analysis — the check-in IS the reading, and it lives on
/// its own screen.
class FactorsCard extends ConsumerWidget {
  const FactorsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    if (!ref.watch(hasPremiumProvider)) {
      return InsightCard(
        trailing: const PremiumBadge(),
        child: PremiumUnlockPrompt(message: l10n.premiumLockedFactors),
      );
    }

    return InsightCard(
      onInfo: () => AnalysisInfoSheet(
        title: l10n.factorsCardTitle,
        paragraphs: <String>[
          l10n.factorsExplain1,
          l10n.factorsExplain2,
          l10n.factorsExplain3,
        ],
      ).show(context),
      child: switch (ref.watch(factorMapProvider)) {
        AsyncData<FactorMap>(value: final FactorMap map) => _Map(map: map),
        // The card is a stack of rows and always the same stack, so the wait is drawn in that shape rather than spun for.
        _ => const SdListSkeletonV2(),
      },
    );
  }
}
