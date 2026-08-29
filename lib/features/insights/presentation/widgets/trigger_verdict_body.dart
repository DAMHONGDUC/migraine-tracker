import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/trigger_factor_label.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/trigger_verdict.dart';
import '../../providers.dart';

/// The answer the app was installed for, in one sentence: is weather actually your trigger?
class TriggerVerdictBody extends ConsumerWidget {
  const TriggerVerdictBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final TriggerVerdict verdict = ref.watch(triggerVerdictProvider);

    return switch (verdict) {
      TriggerVerdictPending(:final int attacksAnalyzed, :final int
          requiredAttacks) =>
        _Verdict(
          headline: l10n.insightsVerdictPending(
            attacksAnalyzed,
            requiredAttacks,
          ),
          muted: true,
        ),
      TriggerVerdictAnswer(weatherIsATrigger: true) => _Verdict(
        headline: l10n.insightsVerdictWeatherYes,
        detail: _alternativeLine(l10n, verdict),
      ),
      TriggerVerdictAnswer(weatherRuledOut: true) => _Verdict(
        headline: l10n.insightsVerdictWeatherNo,
        detail:
            _alternativeLine(l10n, verdict) ?? l10n.insightsVerdictNoPattern,
      ),
      // Something settled, but not pressure — nothing may be said about the weather either way, so only the alternative is stated.
      TriggerVerdictAnswer() => _Verdict(
        headline:
            _alternativeLine(l10n, verdict) ?? l10n.insightsVerdictNoPattern,
        muted: true,
      ),
    };
  }

  String? _alternativeLine(AppLocalizations l10n, TriggerVerdict verdict) {
    if (verdict case TriggerVerdictAnswer(alternative: final TriggerStrength
        alternative)) {
      return l10n.insightsVerdictAlternative(alternative.factor.label(l10n));
    }

    return null;
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.headline, this.detail, this.muted = false});

  final String headline;
  final String? detail;

  /// A sentence that says "not yet" or "nothing stands out" is not the finding the card is for, so it does not get the finding's weight.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          headline,
          style: muted
              ? AppTextStyle.bodyMedium.secondary
              : AppTextStyle.titleMedium,
        ),
        if (detail case final String detail) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h4),
          Text(detail, style: AppTextStyle.bodySmall.secondary),
        ],
      ],
    );
  }
}
